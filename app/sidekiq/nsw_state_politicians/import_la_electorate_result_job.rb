# Imports one NSW LA electorate's first-preference results -- records each unsuccessful candidate
# whose party already has a Group (see NswStatePoliticians::RecordLaCandidate for the gate/what
# gets recorded). The winner is skipped here (already recorded by
# NswStatePoliticians::IngestElectionResultsJob from the statewide "elected" page, which is the
# only page that actually indicates who won -- fp_summary has no win/loss column).
class NswStatePoliticians::ImportLaElectorateResultJob
  include Sidekiq::Job

  sidekiq_options(
    queue: :low,
    lock: :until_executed,
    on_conflict: :log,
    retry: 3
  )

  def perform(event_id, electorate_slug, winner_name = nil)
    url = fp_summary_url(event_id, electorate_slug)
    page = Councils::PageDownloader.call(url)
    raise "Failed to download NSW LA fp_summary page: #{url}" if page.blank?

    candidates = NswStatePoliticians::La::FpSummaryParser.call(page)
    raise "No candidates found on NSW LA fp_summary page: #{url}" if candidates.blank?

    candidates.each do |candidate|
      next if candidate[:name] == winner_name

      NswStatePoliticians::RecordLaCandidate.call(event_id:, electorate: electorate_slug, name: candidate[:name], party: candidate[:party], elected: false, source_url: url)
    end
  rescue StandardError => e
    Rails.logger.error "Error processing NswStatePoliticians::ImportLaElectorateResultJob(#{electorate_slug}): #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: fp_summary_url(event_id, electorate_slug), message: e.message)
    raise e
  end

  private

  def fp_summary_url(event_id, electorate_slug)
    "https://pastvtr.elections.nsw.gov.au/#{event_id}/LA/#{electorate_slug}/cc/fp_summary"
  end
end
