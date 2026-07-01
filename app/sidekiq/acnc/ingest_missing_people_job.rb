require 'sidekiq-scheduler'

class Acnc::IngestMissingPeopleJob
  include Sidekiq::Job

  def perform
    # lightweight query to find charities without people (20 at a time to avoid trouble)
    charities = Group.find_by(name: 'Charities').groups
    charities_without_people = charities.left_joins(:people).where(people: { id: nil }).limit(20)

    charities_without_people.each do |charity|
      Acnc::IngestSingleCharityPeopleJob.perform_async(charity.id)
    end

  rescue StandardError => e
    Rails.logger.error "Error processing Acnc::IngestMissingPeopleJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end
end
