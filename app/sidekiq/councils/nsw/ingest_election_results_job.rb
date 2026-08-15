require 'sidekiq-scheduler'

# Top-level ingest job for NSW council election results -- discovers every council
# from the NSW Electoral Commission's results index and fans out to
# Councils::Nsw::ImportCouncilResultRowJob per council, staggered to avoid hammering
# the Commission's site.
class Councils::Nsw::IngestElectionResultsJob
  include Sidekiq::Job
  sidekiq_options queue: :low

  IMPORT_SPACING = 9.seconds

  def perform(election_id = Councils::Nsw::Elections.latest[:id])
    url = index_url(election_id)
    page = Councils::PageDownloader.call(url)
    raise "Failed to download NSW council index: #{url}" if page.blank?

    councils = Councils::Nsw::ResultsIndexParser.call(page)
    raise "No councils found on NSW council index: #{url}" if councils.blank?

    councils.each_with_index do |council, index|
      Councils::Nsw::ImportCouncilResultRowJob.perform_in(index * IMPORT_SPACING, council[:name], council[:slug], election_id)
    end
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Nsw::IngestElectionResultsJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: index_url(election_id), message: e.message)
    raise e
  end

  private

  def index_url(election_id)
    "https://pastvtr.elections.nsw.gov.au/#{election_id}/index"
  end
end
