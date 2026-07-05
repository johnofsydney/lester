require 'sidekiq-scheduler'

class Acnc::IngestDatasetCsvJob
  include Sidekiq::Job

  def perform
    AcncCharities::IngestCsv.call
  rescue StandardError => e
    Rails.logger.error "Error processing Acnc::IngestDatasetCsvJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end
end
