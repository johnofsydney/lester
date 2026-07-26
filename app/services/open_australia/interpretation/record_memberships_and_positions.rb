class OpenAustralia::Interpretation::RecordMembershipsAndPositions
  FEDERAL_PARTY_POSITION_TITLE = 'Federal Parliamentary Party Member'.freeze
  MINOR_PARTY_POSITION_TITLE = 'Party Member'.freeze
  EVIDENCE_URL = 'https://www.openaustralia.org.au'.freeze

  def self.call(person:) = new(person: person).call

  def initialize(person:)
    @person = person
  end

  def call
    return if person.open_australia_data.blank?

    record_parliament_memberships
    record_party_affiliations
  end

  private

  attr_reader :person

  def record_parliament_memberships
    extracted_periods.parliament_periods.each do |period|
      membership = find_or_create_membership(group: Group.federal_parliament, start_date: period.start_date)
      close_if_changed(membership, period.end_date)
      upsert_position(membership, title: period.position, start_date: period.start_date, end_date: period.end_date)
    end
  end

  # A Major Party gets two Memberships (Federal Branch, closed when the parliamentary term
  # ends, and State Branch, never closed) — a Minor Party gets one, never closed, since it has
  # no Federal/State split (CONTEXT.md).
  def record_party_affiliations
    party_affiliations.party_affiliations.each do |affiliation|
      if affiliation.major
        record_federal_branch(affiliation)
        record_state_branch(affiliation)
      else
        record_minor_party(affiliation)
      end
    end
  end

  def record_federal_branch(affiliation)
    group = Groups::RecordGroup.call(affiliation.federal_group_name)
    membership = find_or_create_membership(group: group, start_date: affiliation.start_date)
    close_if_changed(membership, affiliation.end_date)
    upsert_position(membership, title: FEDERAL_PARTY_POSITION_TITLE, start_date: affiliation.start_date, end_date: affiliation.end_date)
  end

  def record_state_branch(affiliation)
    return unless affiliation.state_group_name

    group = Groups::RecordGroup.call(affiliation.state_group_name)
    membership = find_or_create_never_closed_membership(group: group, start_date: affiliation.start_date)
    upsert_position(membership, title: "Party Member (#{affiliation.state})", start_date: membership.start_date, end_date: nil)
  end

  # For a Minor Party affiliation, ResolvePartyAffiliations puts its one resolved canonical
  # Group name in federal_group_name — there's no separate state name, since Minor Parties
  # have no Federal/State split.
  def record_minor_party(affiliation)
    group = Groups::RecordGroup.call(affiliation.federal_group_name)
    membership = find_or_create_never_closed_membership(group: group, start_date: affiliation.start_date)
    upsert_position(membership, title: MINOR_PARTY_POSITION_TITLE, start_date: membership.start_date, end_date: nil)
  end

  def find_or_create_membership(group:, start_date:)
    Membership.find_or_create_by!(member: person, group: group, start_date: start_date) do |m|
      m.evidence = EVIDENCE_URL
    end
  end

  def find_or_create_never_closed_membership(group:, start_date:)
    Membership.find_or_create_by!(member: person, group: group) do |m|
      m.start_date = start_date
      m.evidence = EVIDENCE_URL
    end
  end

  def close_if_changed(membership, end_date)
    membership.update!(end_date: end_date) if membership.end_date != end_date
  end

  def upsert_position(membership, title:, start_date:, end_date:)
    position = membership.positions.find_or_initialize_by(title: title)
    position.start_date ||= start_date
    position.end_date = end_date
    position.save!
  end

  def extracted_periods
    @extracted_periods ||= OpenAustralia::Interpretation::ExtractPeriods.call(person.open_australia_data)
  end

  def party_affiliations
    @party_affiliations ||= OpenAustralia::Interpretation::ResolvePartyAffiliations.call(person.open_australia_data)
  end
end
