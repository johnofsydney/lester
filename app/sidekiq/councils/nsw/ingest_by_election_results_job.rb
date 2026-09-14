require 'sidekiq-scheduler'

# Top-level ingest job for NSW council by-election/countback results -- discovers every event
# with a modern results.elections.nsw.gov.au report from NSWEC's own local-election-results
# archive page and fans out to Councils::Nsw::ImportByElectionResultRowJob per event, staggered to
# avoid hammering elections.nsw.gov.au. A re-run picks up newly-added events automatically, since
# they simply appear as new entries in the live archive page -- no separate backfill job,
# mirroring Councils::Qld::IngestElectionResultsJob.
class Councils::Nsw::IngestByElectionResultsJob
  include Sidekiq::Job
  sidekiq_options queue: :low

  ARCHIVE_URL = 'https://www.elections.nsw.gov.au/elections/past-results/local-election-results'.freeze
  IMPORT_SPACING = 4.seconds

  def perform
    page = Councils::PageDownloader.call(ARCHIVE_URL)
    raise "Failed to download NSW by-election/countback archive: #{ARCHIVE_URL}" if page.blank?

    events = Councils::Nsw::ByElectionIndexParser.call(page)
    raise "No NSW by-election/countback events found on #{ARCHIVE_URL}" if events.blank?

    events.each_with_index do |event, index|
      Councils::Nsw::ImportByElectionResultRowJob.perform_in(index * IMPORT_SPACING, event[:lb_id], event[:report_url], event[:council_description])
    end
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Nsw::IngestByElectionResultsJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: ARCHIVE_URL, message: e.message)
    raise e
  end
end
