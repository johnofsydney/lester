# The main entry point for ingesting contracts published or modified on a specific date

class IngestContractsDateJob
  include Sidekiq::Job

  def perform(date)
    date = Date.parse(date)
    beginning_of_day = date.beginning_of_day.iso8601
    end_of_day = date.end_of_day.iso8601

    url = "https://api.tenders.gov.au/ocds/findByDates/contractLastModified/#{beginning_of_day}/#{end_of_day}"

    TenderIngestor.process_for_url(url:)
  rescue StandardError => e
    Rails.logger.error "Error processing URL #{url}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    # Optionally, you can re-raise the error if you want Sidekiq to retry the job
  end
end
