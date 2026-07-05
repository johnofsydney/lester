require 'sidekiq-scheduler'

class Acnc::IngestSingleCharityPeopleJob
  include Sidekiq::Job

  sidekiq_options queue: :low,
                  lock: :until_executed,
                  on_conflict: :log,
                  retry: 3

  def perform(charity_id)
    charity = Group.find(charity_id)
    AcncCharities::FetchSingleCharityPeople.call(charity)

  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Charity not found for Acnc::IngestSingleCharityPeopleJob: #{charity_id}"
    ApiLog.create(message: e.message)
    # Don't re-raise - this won't be fixed by retrying
  rescue ResponseFailed, NoResultsFound => e
    # anticipated errors
    Rails.logger.error "Error processing Acnc::IngestSingleCharityPeopleJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  rescue Net::ReadTimeout => e
    Rails.logger.error "Error processing Acnc::IngestSingleCharityPeopleJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  rescue StandardError => e
    Rails.logger.error "Error processing Acnc::IngestSingleCharityPeopleJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end
end
