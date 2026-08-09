require 'sidekiq-scheduler'

# Top-level ingest job for NSW council election results -- discovers every council
# from the NSW Electoral Commission's results index and fans out to
# Councils::Nsw::ImportCouncilResultRowJob per council, staggered to avoid hammering
# the Commission's site.
class Councils::Nsw::IngestElectionResultsJob
  include Sidekiq::Job

  INDEX_URL = 'https://pastvtr.elections.nsw.gov.au/LG2401/index'.freeze

  def perform
    page = Councils::PageDownloader.call(INDEX_URL)
    raise "Failed to download NSW council index: #{INDEX_URL}" if page.blank?

    councils = Councils::Nsw::ResultsIndexParser.call(page)
    raise "No councils found on NSW council index: #{INDEX_URL}" if councils.blank?

    councils.each do |council|
      Councils::Nsw::ImportCouncilResultRowJob.perform_in(rand(1..60).seconds, council[:name], council[:slug])
    end
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Nsw::IngestElectionResultsJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: INDEX_URL, message: e.message)
    raise e
  end
end
