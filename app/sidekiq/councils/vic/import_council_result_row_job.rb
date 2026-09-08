# Imports one VIC council's declared councillor election results for a given election cycle
# (Councils::Vic::Elections): records each elected candidate as a Person with an undated
# Councillor Membership, and appends a raw, dated observation to Person#council_election_data for
# a future interpretation pass to derive real tenure dates from (see
# People::RecordCouncilElectionData -- VEC's declared date only tells us "elected in this cycle,"
# not a councillor's true start, so no date is recorded on the Membership/Position itself).
# Unlike NSW, VEC results pages don't show party affiliation, so no party membership is recorded
# here.
class Councils::Vic::ImportCouncilResultRowJob
  include Sidekiq::Job

  sidekiq_options(
    queue: :low,
    lock: :until_executed,
    on_conflict: :log,
    retry: 3
  )

  STATE = :vic
  LOCAL_COUNCILS_TAG_NAME = 'Australian Local Councils'.freeze

  def perform(council_name, council_slug, election_year = Councils::Vic::Elections.latest[:year])
    election = Councils::Vic::Elections.find(election_year)

    url = "https://www.vec.vic.gov.au/results/council-election-results/#{election[:year]}-council-election-results/#{council_slug}"
    page = Councils::PageDownloader.call(url)
    raise "Failed to download VIC council results: #{url}" if page.blank?

    result = Councils::Vic::CouncillorResultsParser.call(page)
    return if result.blank? # not yet declared -- nothing to record yet

    council = Groups::RecordGroup.call(council_name)
    council.add_to_tag(tag_name: LOCAL_COUNCILS_TAG_NAME)

    evidence = "Victorian Electoral Commission #{election[:year]} council election declared results (#{url})"
    declared_date = declared_date(election:, result:)
    result[:candidates].each do |candidate|
      record_candidate(council:, council_slug:, candidate:, declared_date:, evidence:, election:, source_url: url)
    end
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Vic::ImportCouncilResultRowJob(#{council_name}): #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: url, message: e.message)
    raise e
  end

  private

  # The page's own "Last updated" date is only trustworthy for the live/latest cycle -- for any
  # backfilled cycle it reflects whenever VEC last regenerated the page, not the real historical
  # declaration date (confirmed live: every 2020 council page reports the same November 2024
  # "Last updated" stamp). Fall back to that cycle's known state-wide election_date instead.
  def declared_date(election:, result:)
    return result[:declared_date] if Councils::Vic::Elections.latest?(election[:year])

    election[:election_date]
  end

  def record_candidate(council:, council_slug:, candidate:, declared_date:, evidence:, election:, source_url:)
    person = RecordCandidatePerson.call(name: candidate[:name], scope_group: council)

    Group::RecordRow.new(group: council, person:, title: 'Councillor', evidence:).call
    record_election_data(person:, council:, council_slug:, declared_date:, election:, source_url:)
  end

  def record_election_data(person:, council:, council_slug:, declared_date:, election:, source_url:)
    People::RecordCouncilElectionData.call(
      person:,
      observation: {
        state: STATE,
        council_name: council.name,
        council_slug:,
        cycle: election[:year],
        declared_date:,
        party: nil,
        source_url:
      }
    )
  end
end
