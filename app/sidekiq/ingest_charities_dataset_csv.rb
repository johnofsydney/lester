# The main entry point for ingesting the dataset CSV for all Charities
require 'sidekiq-scheduler'

class IngestCharitiesDatasetCsv
  include Sidekiq::Job

  def perform
    AcncCharities::IngestCsv.perform

  rescue StandardError => e
    Rails.logger.error "Error processing IngestCharitiesDatasetCsv: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end
end
