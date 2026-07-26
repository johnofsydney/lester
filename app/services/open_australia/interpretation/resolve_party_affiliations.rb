class OpenAustralia::Interpretation::ResolvePartyAffiliations
  include OpenAustralia::Interpretation::RawTermDates
  private :contiguous?, :parse_date

  # Checked in order, first match wins. Liberal National Party is checked ahead of the bare
  # Nationals pattern so it resolves to the :liberals family, matching the existing convention
  # in MapGroupNamesAecRecipients (a bare "Liberal National Party" string maps to
  # group_names.liberals.federal, not .nationals.federal).
  MAJOR_PARTY_FAMILIES = [
    [:liberals, /Liberal National Party/i],
    [:nationals, /The Nationals|^Nationals|National Party/i],
    [:labor, /Australian Labor Party/i],
    [:liberals, /Liberal Party/i],
    [:greens, /Australian Greens/i]
  ].freeze

  OFFICE_HOLDER_PARTY_VALUES = %w[Speaker Deputy-Speaker President Deputy-President].freeze

  # OpenAustralia gives Senators their state directly (e.g. "Queensland"), unlike MPs who only
  # get an electorate name (needs MapElectorateToState). This is the full set — a Senate seat is
  # always a state or territory, never an electorate.
  SENATE_STATE_ABBREVIATIONS = {
    'New South Wales' => 'NSW',
    'Victoria' => 'VIC',
    'Queensland' => 'QLD',
    'South Australia' => 'SA',
    'Western Australia' => 'WA',
    'Tasmania' => 'TAS',
    'Northern Territory' => 'NT',
    'Australian Capital Territory' => 'ACT'
  }.freeze

  PartyAffiliationPeriod = Struct.new(
    :party, :major, :federal_group_name, :state, :state_group_name, :start_date, :end_date,
    keyword_init: true
  )
  Result = Struct.new(:party_affiliations, keyword_init: true)

  def self.call(raw_terms) = new(raw_terms).call

  def initialize(raw_terms)
    @terms = raw_terms.sort_by { |term| term['entered_house'] }
  end

  def call
    Result.new(party_affiliations:)
  end

  private

  attr_reader :terms

  def party_affiliations
    terms_with_effective_party
      .chunk_while { |prev, curr| contiguous?(prev[:term], curr[:term]) && prev[:effective_party] == curr[:effective_party] }
      .filter_map { |group| build_affiliation_period(group) }
  end

  def terms_with_effective_party
    terms.each_with_index.map { |term, index| { term: term, effective_party: effective_party_for(term, index) } }
  end

  # ADR-0003: an Office Holder Term (party field overwritten with "Speaker" etc.) is attributed
  # to the most recent preceding Term with a real party, skipping past any other Office Holder
  # (and Independent) Terms in between.
  def effective_party_for(term, index)
    raw_party = term['party'].to_s.strip
    return raw_party unless office_holder?(raw_party)

    terms[0...index].reverse_each do |candidate|
      candidate_party = candidate['party'].to_s.strip
      return candidate_party if real_party?(candidate_party)
    end

    nil
  end

  def office_holder?(party) = OFFICE_HOLDER_PARTY_VALUES.include?(party)
  def independent?(party) = party.blank? || party.match?(/\AIndependent\z/i)
  def real_party?(party) = !independent?(party) && !office_holder?(party)

  # Independent (and an Office Holder Term with no resolvable preceding real party) produce no
  # affiliation period at all — there's no Group for "no party". The gap this leaves is enough
  # on its own to correctly bound the neighbouring real-party periods' start/end dates.
  def build_affiliation_period(group)
    effective_party = group.first[:effective_party]
    return nil if effective_party.blank? || independent?(effective_party)

    first_term = group.first[:term]
    last_term = group.last[:term]
    family = major_party_family(effective_party)
    state = family && state_for(first_term)

    PartyAffiliationPeriod.new(
      party: effective_party,
      major: family.present?,
      federal_group_name: federal_group_name(effective_party, family),
      state: state,
      state_group_name: state && Group::NAMES.send(family).send(state.downcase.to_sym),
      start_date: parse_date(first_term['entered_house']),
      end_date: parse_date(last_term['left_house'])
    )
  end

  def major_party_family(party)
    MAJOR_PARTY_FAMILIES.find { |_family, pattern| pattern.match?(party) }&.first
  end

  # Major parties resolve directly against Group::NAMES — a complete, unambiguous table.
  # Minor parties go through the existing AEC name mapper for its alias-cleanup rules.
  def federal_group_name(party, family)
    return Group::NAMES.send(family).federal if family

    minor_party_mapper.call(party)
  end

  def state_for(term)
    term['house'] == '2' ? senate_state(term['constituency']) : MapElectorateToState.lookup(term['constituency'])
  end

  def senate_state(constituency)
    SENATE_STATE_ABBREVIATIONS[constituency.to_s]
  end

  def minor_party_mapper
    @minor_party_mapper ||= MapGroupNamesAecRecipients.new
  end
end
