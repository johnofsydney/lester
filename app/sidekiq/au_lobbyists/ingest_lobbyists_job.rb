require 'sidekiq-scheduler'

class AuLobbyists::IngestLobbyistsJob
  include Sidekiq::Job

  def perform
    AuLobbyists::IngestLobbyists.call
    IngestSourceStatus.record_success(self.class.name)
  rescue StandardError => e
    Rails.logger.error "Error processing AuLobbyists::IngestLobbyistsJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    IngestSourceStatus.record_failure(self.class.name, e)
    raise e
  end
end
