# The main entry point for ingesting contracts published or modified on a specific date
require 'sidekiq-scheduler'

class IngestContractsDateJob
  include Sidekiq::Job

  def perform(date = Date.yesterday.to_s)
    date = Date.parse(date)
    beginning_of_day = date.beginning_of_day.iso8601
    end_of_day = date.end_of_day.iso8601

    if Rails.env.staging?
      return unless date.day % 4 == 0
    end

    url = "https://api.tenders.gov.au/ocds/findByDates/contractLastModified/#{beginning_of_day}/#{end_of_day}"

    TenderIngestor.process_for_url(url:)
  rescue ApiServerError => e
    Rails.logger.warn "API Server Error for #{url}: #{e.message} - will retry"
    ApiLog.create( endpoint: url, message: e.message)
    raise e
  rescue StandardError => e
    Rails.logger.error "Error processing URL #{url}: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create( endpoint: url, message: e.message)
    raise e
  end
end
