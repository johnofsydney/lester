# Fetches and parses one QLD election stub's declared results, then fans out one
# Councils::Qld::RecordContestResultJob per contest -- deliberately does no recording itself, so a
# single malformed contest inside a stub's ~343-entry JSON only ever blocks/retries its own
# RecordContestResultJob, not the whole election.
class Councils::Qld::ImportElectionResultsJob
  include Sidekiq::Job
  sidekiq_options(
    queue: :low,
    lock: :until_executed,
    on_conflict: :log,
    retry: 3
  )

  def perform(stub)
    contests = Councils::Qld::DeclaredResultsParser.call(stub)
    return if contests.blank? # nothing declared yet for this election

    contests.each { |contest| record_contest(stub, contest) }
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Qld::ImportElectionResultsJob(#{stub}): #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: stub, message: e.message)
    raise e
  end

  private

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
end
