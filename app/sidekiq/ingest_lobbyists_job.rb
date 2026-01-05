# The main entry point for ingesting the dataset CSV for all Charities
require 'sidekiq-scheduler'

class IngestLobbyistsJob
  include Sidekiq::Job

  def perform
    AuLobbyists::IngestLobbyists.call

  rescue StandardError => e
    Rails.logger.error "Error processing IngestLobbyistsJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end
end
