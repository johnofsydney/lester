# The main entry point for ingesting people who are connected to charities
require 'sidekiq-scheduler'

class IngestSingleCharitiesPeopleJob
  include Sidekiq::Job

  # skipped!

  sidekiq_options queue: :low,
                  lock: :until_executed,
                  on_conflict: :log,
                  retry: 3

  def perform(charity_id)
    charity = Group.find(charity_id)
    AcncCharities::FetchSingleCharityPeople.perform(charity)

  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Charity not found for IngestSingleCharitiesPeopleJob: #{charity_id}"
    ApiLog.create(message: e.message)
    # Don't re-raise - this won't be fixed by retrying
  rescue StandardError => e
    Rails.logger.error "Error processing IngestSingleCharitiesPeopleJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end
end
