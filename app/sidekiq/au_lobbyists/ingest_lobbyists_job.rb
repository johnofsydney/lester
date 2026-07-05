require 'sidekiq-scheduler'

class AuLobbyists::IngestLobbyistsJob
  include Sidekiq::Job

  def perform
    AuLobbyists::IngestLobbyists.call
  rescue StandardError => e
    Rails.logger.error "Error processing AuLobbyists::IngestLobbyistsJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end
end
