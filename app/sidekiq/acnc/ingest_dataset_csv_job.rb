require 'sidekiq-scheduler'

class Acnc::IngestDatasetCsvJob
  include Sidekiq::Job

  def perform
    AcncCharities::IngestCsv.call
    IngestSourceStatus.record_success(self.class.name)
  rescue StandardError => e
    Rails.logger.error "Error processing Acnc::IngestDatasetCsvJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    IngestSourceStatus.record_failure(self.class.name, e)
    raise e
  end
end
