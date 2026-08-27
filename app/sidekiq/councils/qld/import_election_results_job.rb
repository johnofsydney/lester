# Fetches one QLD election stub's declared-results and electorates JSON, parses them via
# Councils::Qld::DeclaredResultsParser, then fans out one Councils::Qld::RecordContestResultJob per
# contest -- deliberately does no recording itself, so a single malformed contest inside a stub's
# ~343-entry JSON only ever blocks/retries its own RecordContestResultJob, not the whole election.
class Councils::Qld::ImportElectionResultsJob
  include Sidekiq::Job
  sidekiq_options(
    queue: :low,
    lock: :until_executed,
    on_conflict: :log,
    retry: 3
  )

  DECLARED_CANDIDATES_URL = 'https://resultsdata.elections.qld.gov.au/%<stub>s-declared_candidates.json'.freeze
  ELECTORATES_URL = 'https://resultsdata.elections.qld.gov.au/%<stub>s-electorates.json'.freeze

  def perform(stub)
    contests = Councils::Qld::DeclaredResultsParser.call(
      declared_candidates_page: fetch(declared_candidates_url(stub), 'declared candidates'),
      electorates_page: fetch(electorates_url(stub), 'electorates'),
      source_url: declared_candidates_url(stub),
      known_council_names: Councils::Qld::KnownCouncils.names
    )
    return if contests.blank? # nothing declared yet for this election

    contests.each { |contest| record_contest(stub, contest) }
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Qld::ImportElectionResultsJob(#{stub}): #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: stub, message: e.message)
    raise e
  end

  private

  def fetch(url, label)
    page = Councils::PageDownloader.call(url)
    raise "Failed to download QLD #{label}: #{url}" if page.blank?

    page
  end

  def record_contest(stub, contest)
    Councils::Qld::RecordContestResultJob.perform_async(
      stub,
      contest[:council_name],
      contest[:contest_name],
      contest[:contest_type],
      contest[:candidates].as_json,
      contest[:declared_date].iso8601,
      contest[:source_url]
    )
  end

  def declared_candidates_url(stub) = format(DECLARED_CANDIDATES_URL, stub:)
  def electorates_url(stub) = format(ELECTORATES_URL, stub:)
end
