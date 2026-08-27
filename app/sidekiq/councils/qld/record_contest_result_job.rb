# Records one QLD declared contest (a council's mayoral race, or one division/ward's councillor
# race) as a Person with an undated Membership/Position (see People::RecordCouncilElectionData --
# ECQ's declared date only tells us "elected in this cycle," not a councillor's true start, so no
# date is recorded on the Membership/Position itself), links party affiliation where shown, and
# appends a raw, dated observation to Person#council_election_data for a future interpretation pass
# to derive real tenure dates from.
class Councils::Qld::RecordContestResultJob
  include Sidekiq::Job

  sidekiq_options(
    queue: :low,
    lock: :until_executed,
    on_conflict: :log,
    retry: 3
  )

  STATE = :qld
  LOCAL_COUNCILS_TAG_NAME = 'Australian Local Councils'.freeze

  def perform(stub, council_name, contest_name, contest_type, candidates, declared_date, source_url)
    council = Groups::RecordGroup.call("#{council_name} Council")
    council.add_to_tag(tag_name: LOCAL_COUNCILS_TAG_NAME)

    evidence = "Electoral Commission of Queensland #{Date.parse(declared_date).year} Local Government election declared results for #{contest_name} (#{contest_type}) (#{source_url})"

    candidates.each do |candidate|
      record_candidate(council:, council_slug: council_name, contest_type:, candidate:, declared_date:, evidence:, stub:, source_url:)
    end
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Qld::RecordContestResultJob(#{stub}, #{contest_name}): #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: source_url, message: e.message)
    raise e
  end

  private

  def record_candidate(council:, council_slug:, contest_type:, candidate:, declared_date:, evidence:, stub:, source_url:)
    person = RecordCandidatePerson.call(name: candidate['name'], scope_group: council)

    Group::RecordRow.new(group: council, person:, title: title_for(contest_type), evidence:).call
    record_party_membership(person:, candidate:, evidence:)
    record_election_data(person:, council:, council_slug:, candidate:, declared_date:, stub:, source_url:)
  end

  def title_for(contest_type) = contest_type == 'mayor' ? 'Mayor' : 'Councillor'

  def record_party_membership(person:, candidate:, evidence:)
    party_group = Councils::PartyMapper.call(candidate['party'], state: STATE)
    return if party_group.nil?

    Group::RecordRow.new(group: party_group, person:, evidence:).call
  end

  def record_election_data(person:, council:, council_slug:, candidate:, declared_date:, stub:, source_url:)
    People::RecordCouncilElectionData.call(
      person:,
      observation: {
        state: STATE,
        council_name: council.name,
        council_slug:,
        cycle: stub,
        declared_date:,
        party: candidate['party'],
        source_url:
      }
    )
  end
end
