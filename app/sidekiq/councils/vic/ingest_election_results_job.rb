require 'sidekiq-scheduler'

# Top-level ingest job for VIC council election results -- discovers every council
# from the Victorian Electoral Commission's results index and fans out to
# Councils::Vic::ImportCouncilResultRowJob per council, staggered to avoid hammering
# the Commission's site.
class Councils::Vic::IngestElectionResultsJob
  include Sidekiq::Job

  INDEX_URL = 'https://www.vec.vic.gov.au/results/council-election-results/2024-council-election-results'.freeze
  IMPORT_SPACING = 11.seconds

  def perform
    page = Councils::PageDownloader.call(INDEX_URL)
    raise "Failed to download VIC council index: #{INDEX_URL}" if page.blank?

    councils = Councils::Vic::ResultsIndexParser.call(page)
    raise "No councils found on VIC council index: #{INDEX_URL}" if councils.blank?

    councils.each_with_index do |council, index|
      Councils::Vic::ImportCouncilResultRowJob.perform_in(index * IMPORT_SPACING, council[:name], council[:slug])
    end
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Vic::IngestElectionResultsJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: INDEX_URL, message: e.message)
    raise e
  end
end
