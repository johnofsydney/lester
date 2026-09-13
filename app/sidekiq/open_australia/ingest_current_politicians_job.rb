require 'sidekiq-scheduler'

class OpenAustralia::IngestCurrentPoliticiansJob
  include Sidekiq::Job

  def perform
    OpenAustralia::IngestCurrentPoliticians.call
    IngestSourceStatus.record_success(self.class.name)
  rescue StandardError => e
    Rails.logger.error "Error processing OpenAustralia::IngestCurrentPoliticiansJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    IngestSourceStatus.record_failure(self.class.name, e)
    raise e
  end
end
