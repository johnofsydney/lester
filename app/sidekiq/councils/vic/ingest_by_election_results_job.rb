require 'sidekiq-scheduler'

# Top-level ingest job for VIC council by-election and countback results -- discovers every event
# since ~2010 from VEC's own by-election/countback timeline and fans out to
# Councils::Vic::ImportByElectionResultRowJob per event, staggered to avoid hammering vec.vic.gov.au.
# A re-run picks up newly-added events automatically, since they simply appear as new rows in the
# live timeline page -- no separate backfill job, mirroring Councils::Qld::IngestElectionResultsJob.
class Councils::Vic::IngestByElectionResultsJob
  include Sidekiq::Job
  sidekiq_options queue: :low

  TIMELINE_URL = 'https://www.vec.vic.gov.au/results/council-election-results/council-by-elections-and-countbacks-timeline'.freeze
  IMPORT_SPACING = 4.seconds

  def perform
    page = Councils::PageDownloader.call(TIMELINE_URL)
    raise "Failed to download VIC by-election/countback timeline: #{TIMELINE_URL}" if page.blank?

    events = Councils::Vic::ByElectionIndexParser.call(page)
    raise "No VIC by-election/countback events found on #{TIMELINE_URL}" if events.blank?

    events.each_with_index do |event, index|
      Councils::Vic::ImportByElectionResultRowJob.perform_in(index * IMPORT_SPACING, event[:slug], event[:kind].to_s, event[:council_description])
    end
    IngestSourceStatus.record_success(self.class.name)
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Vic::IngestByElectionResultsJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    IngestSourceStatus.record_failure(self.class.name, e)
    raise e
  end
end
