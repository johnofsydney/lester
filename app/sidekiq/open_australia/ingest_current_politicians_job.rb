require 'sidekiq-scheduler'

class OpenAustralia::IngestCurrentPoliticiansJob
  include Sidekiq::Job

  def perform
    OpenAustralia::IngestCurrentPoliticians.call
  rescue StandardError => e
    Rails.logger.error "Error processing OpenAustralia::IngestCurrentPoliticiansJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end
end
