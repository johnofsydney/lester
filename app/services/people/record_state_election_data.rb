# Appends a raw "this person contested this NSW state election in this electorate/house" observation
# to Person#state_election_data, deduped so a re-run of the same event/electorate/house doesn't
# create duplicate entries. Mirrors People::RecordCouncilElectionData -- pastvtr data arrives
# piecemeal (one import run per electorate/event), not as a single full-history API call, so this
# appends rather than overwrites (see ADR-0001 vs ADR-0006 -- this follows ADR-0006's side).
#
# Deliberately records no start_date/end_date on any Membership/Position -- a declared-elected date
# only tells us "elected in this cycle," not a member's true tenure (a re-elected member's real
# first-elected date is unknowable from the cycles this pipeline reaches). This raw data is the
# material a future interpretation pass would need to derive real dates from.
class People::RecordStateElectionData
  DEDUP_KEYS = %w[state event_id house electorate].freeze

  def self.call(person:, observation:) = new(person:, observation:).call

  def initialize(person:, observation:)
    @person = person
    # as_json (not stringify_keys) so values round-trip identically to how they'll read back
    # after the jsonb column serialises them.
    @observation = observation.as_json
  end

  def call
    return person if already_recorded?

    person.update!(
      state_election_data: person.state_election_data + [observation],
      state_election_data_updated_at: Time.current
    )
    person
  end

  private

  attr_reader :person, :observation

  def already_recorded?
    person.state_election_data.any? { |entry| entry.slice(*DEDUP_KEYS) == observation.slice(*DEDUP_KEYS) }
  end
end
