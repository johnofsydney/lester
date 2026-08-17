# Appends a raw "this person was declared elected to this council in this cycle" observation to
# Person#council_election_data, deduped so a re-run of the same council/cycle doesn't create
# duplicate entries. Unlike OpenAustralia's raw Terms (a single API call returns a person's whole
# known history, safe to overwrite -- ADR-0001), council data arrives piecemeal: one observation
# per election result, discovered incrementally across many import runs. So this appends rather
# than overwrites.
#
# Deliberately records no start_date/end_date on any Membership/Position -- NSWEC/VEC's declared
# dates only tell us "elected in this cycle," not a councillor's true tenure (a re-elected
# councillor's real first-elected date is unknowable from the cycles we have). This raw data is
# the material a future interpretation pass (mirroring OpenAustralia::Interpretation) would need
# to derive real dates from, once enough historical depth exists to do that with confidence.
class People::RecordCouncilElectionData
  DEDUP_KEYS = %w[state council_slug cycle].freeze

  def self.call(person:, observation:) = new(person:, observation:).call

  def initialize(person:, observation:)
    @person = person
    # as_json (not stringify_keys) so values round-trip identically to how they'll read back
    # after the jsonb column serialises them -- symbols (state: :nsw) and Dates (declared_date)
    # would otherwise never dedup-match against already-stored entries.
    @observation = observation.as_json
  end

  def call
    return person if already_recorded?

    person.update!(
      council_election_data: person.council_election_data + [observation],
      council_election_data_updated_at: Time.current
    )
    person
  end

  private

  attr_reader :person, :observation

  def already_recorded?
    person.council_election_data.any? { |entry| entry.slice(*DEDUP_KEYS) == observation.slice(*DEDUP_KEYS) }
  end
end
