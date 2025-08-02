class IngestContractsDateJob
  include Sidekiq::Job

  def perform(date)
    p date

      date = date.is_a?(String) ? Date.parse(date) : date
      beginning_of_day = date.beginning_of_day.iso8601
      end_of_day = date.end_of_day.iso8601

      url = "https://api.tenders.gov.au/ocds/findByDates/contractLastModified/#{beginning_of_day}/#{end_of_day}"

    TenderIngestor.process_for_url(url: url)
  rescue StandardError => e
    Rails.logger.error "Error processing URL #{url}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    # Optionally, you can re-raise the error if you want Sidekiq to retry the job
  end
end
