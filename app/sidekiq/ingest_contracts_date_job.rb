class IngestContractsDateJob
  include Sidekiq::Job

  def perform(date)
    date = Date.parse(date)
    beginning_of_day = date.beginning_of_day.iso8601
    end_of_day = date.end_of_day.iso8601

    url = "https://api.tenders.gov.au/ocds/findByDates/contractLastModified/#{beginning_of_day}/#{end_of_day}"

    TenderIngestor.process_for_url(url: url)
  rescue ApiServerError => e
    Rails.logger.warn "API Server Error for #{url}: #{e.message} - will retry"
    ApiLog.create( endpoint: url, message: e.message)
    raise e
  rescue Net::TimeoutError, Faraday::TimeoutError => e
    Rails.logger.warn "Network timeout for #{url}: #{e.message} - will retry"
    ApiLog.create( endpoint: url, message: e.message)
    raise e
  rescue StandardError => e
    Rails.logger.error "Error processing URL #{url}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create( endpoint: url, message: e.message)
    raise e
  end
end
