require 'sidekiq-scheduler'

class OpenAustralia::IngestPoliticiansJob
  include Sidekiq::Job

  def perform
    OpenAustralia::IngestPoliticians.call
  rescue StandardError => e
    Rails.logger.error "Error processing OpenAustralia::IngestPoliticiansJob: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end
