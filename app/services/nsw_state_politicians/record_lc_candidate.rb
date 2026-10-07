# Records one LC candidate row (from either candidates_elected or the group-and-candidates
# roster) per the LC addendum to docs/plans/0011-ingest-nsw-state-politicians-design.md:
#
# - A winner is always ingested, regardless of party -- their party Group is created if it
#   doesn't already exist. They get an undated Membership in the single NSW Parliament Group
#   (Group.nsw_parliament) -- never dated, per ADR-0006 (council precedent).
# - An unsuccessful candidate is only ingested if Councils::PartyMapper resolves their group's
#   declared party to a Group that *already exists*. An ingested unsuccessful candidate never sat
#   in Parliament, so they get NO NSW Parliament Membership -- only the party Membership (undated)
#   and the raw election_data observation below.
#
# Mirrors NswStatePoliticians::RecordLaCandidate exactly; the only house-specific differences are
# the Position title and the electorate value, since LC is one statewide ballot (no electorates).
class NswStatePoliticians::RecordLcCandidate
  POSITION_TITLE = 'Member of the Legislative Council'.freeze
  ELECTORATE = 'statewide'.freeze

  def self.call(event_id:, name:, party:, elected:, source_url:, group_letter: nil, elected_at_count: nil)
    new(event_id:, name:, party:, elected:, source_url:, group_letter:, elected_at_count:).call
  end

  def initialize(event_id:, name:, party:, elected:, source_url:, group_letter:, elected_at_count:)
    @event_id = event_id
    @name = name
    @party = party
    @elected = elected
    @source_url = source_url
    @group_letter = group_letter
    @elected_at_count = elected_at_count
  end

  def call
    return nil if !elected && party_group.nil?

    record_parliament_membership if elected
    record_party_membership
    record_election_data

    person
  end

  private

  attr_reader :event_id, :name, :party, :elected, :source_url, :group_letter, :elected_at_count

  def person
    @person ||= RecordCandidatePerson.call(name: cleaned_name, scope_group: Group.nsw_parliament)
  end

  def cleaned_name
    NswStatePoliticians::CleanCandidateName.call(name)
  end

  def party_group
    return @party_group if defined?(@party_group)

    @party_group = elected ? party_group_for_winner : Councils::PartyMapper.call(party, state: :nsw)
  end

  # Every real party Group in this app is a plain Group (type: nil), not a Tag -- see
  # docs/adr/0011-tag-type-is-for-category-labels-not-organizations.md.
  def party_group_for_winner
    canonical_name = Councils::PartyMapper.resolved_name(party, state: :nsw)
    return nil if canonical_name.blank?

    Group.find_by_name_i(canonical_name) || Group.create!(name: canonical_name) # rubocop:disable Rails/DynamicFindBy -- Group's own custom lookup method
  end

  def evidence
    "NSW Electoral Commission #{event_id} LC election result (#{source_url})"
  end

  def record_parliament_membership
    Group::RecordRow.new(group: Group.nsw_parliament, person:, title: POSITION_TITLE, evidence:).call
  end

  def record_party_membership
    return if party_group.nil?

    Group::RecordRow.new(group: party_group, person:, evidence:).call
  end

  def record_election_data
    People::RecordStateElectionData.call(
      person:,
      observation: {
        state: :nsw,
        event_id:,
        house: 'LC',
        electorate: ELECTORATE,
        elected:,
        party:,
        group_letter:,
        elected_at_count:,
        source_url:
      }
    )
  end
end
