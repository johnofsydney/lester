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
    IngestSourceStatus.record_success(self.class.name)
  rescue ActiveRecord::RecordNotFound, NoResultsFound => e
    Rails.logger.error "Charity not found for Acnc::IngestSingleCharityPeopleJob: #{charity_id}"
    IngestSourceStatus.record_failure(self.class.name, e)
    # Don't re-raise - this won't be fixed by retrying
  rescue ResponseFailed, Net::ReadTimeout => e
    # anticipated errors
    Rails.logger.error "Error processing Acnc::IngestSingleCharityPeopleJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    IngestSourceStatus.record_failure(self.class.name, e)
    raise e
  end
end
