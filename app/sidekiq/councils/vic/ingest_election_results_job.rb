require 'sidekiq-scheduler'

# Top-level ingest job for VIC council election results -- discovers every council
# from the Victorian Electoral Commission's results index and fans out to
# Councils::Vic::ImportCouncilResultRowJob per council, staggered to avoid hammering
# the Commission's site.
class Councils::Vic::IngestElectionResultsJob
  include Sidekiq::Job
  sidekiq_options queue: :low

  IMPORT_SPACING = 4.seconds

  def perform(election_year = Councils::Vic::Elections.latest[:year])
    url = index_url(election_year)
    page = Councils::PageDownloader.call(url)
    raise "Failed to download VIC council index: #{url}" if page.blank?

    councils = Councils::Vic::ResultsIndexParser.call(page)
    raise "No councils found on VIC council index: #{url}" if councils.blank?

    councils.each_with_index do |council, index|
      Councils::Vic::ImportCouncilResultRowJob.perform_in(index * IMPORT_SPACING, council[:name], council[:slug], election_year)
    end
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Vic::IngestElectionResultsJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: index_url(election_year), message: e.message)
    raise e
  end

  private

  def index_url(election_year)
    "https://www.vec.vic.gov.au/results/council-election-results/#{election_year}-council-election-results"
  end
end
