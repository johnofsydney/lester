class OpenAustralia::ImportPoliticianRow
  OFFICE_HOLDER_PARLIAMENT_POSITIONS = {
    'Speaker' => 'Speaker of the House',
    'President' => 'President of the Senate',
    'Deputy-President' => 'Deputy President of the Senate'
  }.freeze

  MAJOR_PARTY_PATTERNS = [
    /Australian Labor Party/i,
    /Liberal Party/i,
    /The Nationals|^Nationals|National Party/i,
    /Australian Greens/i,
    /Liberal National Party/i
  ].freeze

  SENATOR_STATE_NORMALISATION = {
    'Queensland' => 'QLD',
    'Tasmania' => 'TAS',
    'Victoria' => 'VIC'
  }.freeze

  def self.call(person_id:, house:)
    new(person_id:, house:).call
  end

  def initialize(person_id:, house:)
    @person_id = person_id.to_s
    @house     = house
  end

  def call
    terms = fetch_detail
    return nil if terms.empty?

    terms            = terms.sort_by { |t| t['entered_house'] }
    person           = record_person(terms.last)
    parliament_group = Group.federal_parliament

    group_into_stints(terms).each { |stint| record_parliament_membership(person, parliament_group, stint) }
    terms.each { |term| record_party_membership(person, term) }
    apply_party_end_dates(person, terms)

    person
  end

  private

  attr_reader :person_id, :house

  def fetch_detail
    response = representatives? ? api_client.get_representative(person_id) : api_client.get_senator(person_id)
    response.is_a?(Array) ? response : []
  end

  def record_person(term)
    People::RecordPerson.call(term['full_name'], open_australia_id: person_id)
  end

  # Terms where left_house[i] == entered_house[i+1] are a single unbroken parliament stint.
  # Break the stint when a term is an office holder (Speaker, President, etc.) — those get
  # their own membership with a distinct position title.
  def group_into_stints(sorted_terms)
    sorted_terms.chunk_while do |prev, curr|
      prev['left_house'] == curr['entered_house'] && !office_holder?(curr['party'].to_s.strip)
    end.to_a
  end

  def record_parliament_membership(person, parliament_group, stint)
    start_date = parse_date(stint.first['entered_house'])
    end_date   = parse_date(stint.last['left_house'])
    last_party = stint.last['party'].to_s.strip

    membership = Membership.find_or_create_by!(
      member: person,
      group: parliament_group,
      start_date: start_date
    ) do |m|
      m.evidence = 'https://www.openaustralia.org.au'
    end

    membership.update!(end_date:) if membership.end_date != end_date
    position = upsert_position(membership, parliament_position_title(last_party), start_date:)
    position.update!(end_date:) if end_date.present? && position.end_date != end_date
  end

  def record_party_membership(person, term)
    term_party        = term['party'].to_s.strip
    term_constituency = term['constituency'].to_s.strip
    start_date        = parse_date(term['entered_house'])

    return if office_holder?(term_party) || independent?(term_party)

    if major_party?(term_party)
      record_major_party_memberships(person, term_party, term_constituency, start_date:)
    else
      record_minor_party_membership(person, term_party, start_date:)
    end
  end

  def record_major_party_memberships(person, term_party, term_constituency, start_date:)
    federal_group      = Groups::RecordGroup.call("#{term_party} (Federal)", mapper: MapGroupNamesAecRecipients.new)
    federal_membership = Membership.find_or_create_by!(member: person, group: federal_group) do |m|
      m.start_date = start_date
    end
    upsert_position(federal_membership, 'Federal Parliamentary Party Member', start_date:)

    state = resolve_state(term_constituency)
    return unless state

    state_group      = Groups::RecordGroup.call("#{term_party} (#{state})", mapper: MapGroupNamesAecRecipients.new)
    state_membership = Membership.find_or_create_by!(member: person, group: state_group) do |m|
      m.start_date = start_date
    end
    upsert_position(state_membership, "Party Member (#{state})")
  end

  def record_minor_party_membership(person, term_party, start_date:)
    group      = Groups::RecordGroup.call(term_party, mapper: MapGroupNamesAecRecipients.new)
    membership = Membership.find_or_create_by!(member: person, group:) do |m|
      m.start_date = start_date
    end
    upsert_position(membership, 'Federal Parliamentary Party Member', start_date:)
  end

  # After all terms are processed, detect party transitions and close the outgoing
  # party's membership(s) with the date the politician switched.
  def apply_party_end_dates(person, terms)
    terms.each_cons(2) do |current_term, next_term|
      current_party = current_term['party'].to_s.strip
      next_party    = next_term['party'].to_s.strip

      next if current_party == next_party
      next if office_holder?(current_party) || independent?(current_party)

      end_date          = parse_date(next_term['entered_house'])
      term_constituency = current_term['constituency'].to_s.strip

      close_party_memberships(person, current_party, term_constituency, end_date)
    end
  end

  def close_party_memberships(person, term_party, term_constituency, end_date)
    if major_party?(term_party)
      federal_group = Groups::RecordGroup.call("#{term_party} (Federal)", mapper: MapGroupNamesAecRecipients.new)
      Membership.where(member: person, group: federal_group, end_date: nil).find_each do |m|
        m.update!(end_date:)
        m.positions.where(end_date: nil).find_each { |p| p.update!(end_date:) }
      end
      state = resolve_state(term_constituency)
      if state
        state_group = Groups::RecordGroup.call("#{term_party} (#{state})", mapper: MapGroupNamesAecRecipients.new)
        Membership.where(member: person, group: state_group, end_date: nil).find_each { |m| m.update!(end_date:) }
      end
    else
      group = Groups::RecordGroup.call(term_party, mapper: MapGroupNamesAecRecipients.new)
      Membership.where(member: person, group:, end_date: nil).find_each do |m|
        m.update!(end_date:)
        m.positions.where(end_date: nil).find_each { |p| p.update!(end_date:) }
      end
    end
  end

  def upsert_position(membership, title, start_date: nil)
    position = membership.positions.find_or_initialize_by(title:)
    position.start_date ||= start_date
    position.save!
    position
  end

  def parliament_position_title(term_party)
    OFFICE_HOLDER_PARLIAMENT_POSITIONS[term_party] || (representatives? ? 'MP' : 'Senator')
  end

  def office_holder?(term_party)
    OFFICE_HOLDER_PARLIAMENT_POSITIONS.key?(term_party)
  end

  def independent?(term_party)
    term_party.blank? || term_party.match?(/\AIndependent\z/i)
  end

  def major_party?(term_party)
    MAJOR_PARTY_PATTERNS.any? { |pattern| pattern.match?(term_party) }
  end

  def representatives?
    house.to_s == '1'
  end

  def resolve_state(term_constituency)
    if representatives?
      MapElectorateToState.lookup(term_constituency)
    else
      SENATOR_STATE_NORMALISATION.fetch(term_constituency, term_constituency)
    end
  end

  def parse_date(date_string)
    return nil if date_string.blank? || date_string == '9999-12-31'

    Date.parse(date_string)
  rescue Date::Error
    nil
  end

  def api_client
    @api_client ||= OpenAustralia::ApiClient.new
  end
end
