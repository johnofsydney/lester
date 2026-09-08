# Records one LA candidate row (from either the statewide "elected" page or a per-electorate
# fp_summary page) per docs/plans/0011-ingest-nsw-state-politicians-design.md's "Who gets
# ingested" / "What gets recorded" rules:
#
# - A winner is always ingested, regardless of party -- their party Group is created if it
#   doesn't already exist. They get an undated Membership in the single NSW Parliament Group
#   (Group.nsw_parliament) -- never dated, per ADR-0006 (council precedent): election-results
#   data alone can't tell us a member's true tenure.
# - An unsuccessful candidate is only ingested if Councils::PartyMapper resolves their party to a
#   Group that *already exists* -- this is the whole gate (no separate whitelist). Call returns
#   nil (nothing recorded) when this gate isn't met. An ingested unsuccessful candidate never
#   contested a seat they won, so they get NO NSW Parliament Membership -- only the party
#   Membership (undated, same reasoning) and the raw election_data observation below.
#
# A dated raw observation is appended (for both winners and ingested losers) to
# Person#state_election_data for a future interpretation pass to derive real dates from.
class NswStatePoliticians::RecordLaCandidate
  POSITION_TITLE = 'Member of the Legislative Assembly'.freeze

  def self.call(event_id:, electorate:, name:, party:, elected:, source_url:)
    new(event_id:, electorate:, name:, party:, elected:, source_url:).call
  end

  def initialize(event_id:, electorate:, name:, party:, elected:, source_url:)
    @event_id = event_id
    @electorate = electorate
    @name = name
    @party = party
    @elected = elected
    @source_url = source_url
  end

  def call
    return nil if !elected && party_group.nil?

    record_parliament_membership if elected
    record_party_membership
    record_election_data

    person
  end

  private

  attr_reader :event_id, :electorate, :name, :party, :elected, :source_url

  def person
    @person ||= RecordCandidatePerson.call(name: cleaned_name, scope_group: Group.nsw_parliament)
  end

  def cleaned_name
    NswStatePoliticians::CleanCandidateName.call(name)
  end

  # Winners always get their party Group created if it doesn't exist; unsuccessful candidates are
  # already gated on the Group existing (see `call`), so this is only ever a lookup for them.
  def party_group
    return @party_group if defined?(@party_group)

    @party_group = elected ? party_group_for_winner : Councils::PartyMapper.call(party, state: :nsw)
  end

  # Every real party Group in this app is a plain Group (type: nil), not a Tag -- see
  # docs/adr/0011-tag-type-is-for-category-labels-not-organizations.md. `find_by_name_i` (no
  # type filter) matches the existing convention; only fall back to creating a fresh one (also
  # type: nil, matching the convention) when truly nothing exists.
  def party_group_for_winner
    canonical_name = Councils::PartyMapper.resolved_name(party, state: :nsw)
    return nil if canonical_name.blank?

    Group.find_by_name_i(canonical_name) || Group.create!(name: canonical_name) # rubocop:disable Rails/DynamicFindBy -- Group's own custom lookup method
  end

  def evidence
    "NSW Electoral Commission #{event_id} LA election result (#{source_url})"
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
        house: 'LA',
        electorate:,
        elected:,
        party:,
        source_url:
      }
    )
  end
end
