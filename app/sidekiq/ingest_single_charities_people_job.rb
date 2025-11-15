# The main entry point for ingesting people who are connected to charities
require 'sidekiq-scheduler'

class IngestSingleCharitiesPeopleJob
  include Sidekiq::Job

  def perform(charity_id)
    charity = Group.find(charity_id)
    AcncCharities::FetchSingleCharityPeople.perform(charity)

  rescue StandardError => e
    Rails.logger.error "Error processing IngestSingleCharitiesPeopleJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end
end
