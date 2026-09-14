require 'sidekiq-scheduler'

class AusTender::IngestContractsDateJob
  include Sidekiq::Job

  def perform(date = Date.yesterday.to_s)
    date = Date.parse(date)
    beginning_of_day = date.beginning_of_day.iso8601
    end_of_day = date.end_of_day.iso8601

    url = "https://api.tenders.gov.au/ocds/findByDates/contractLastModified/#{beginning_of_day}/#{end_of_day}"

    TenderIngestor.process_for_url(url:)
    IngestSourceStatus.record_success(self.class.name)
  rescue ApiServerError => e
    Rails.logger.warn "API Server Error for #{url}: #{e.message} - will retry"
    IngestSourceStatus.record_failure(self.class.name, e)
    raise e
  rescue StandardError => e
    Rails.logger.error "Error processing URL #{url}: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    IngestSourceStatus.record_failure(self.class.name, e)
    raise e
  end
end
