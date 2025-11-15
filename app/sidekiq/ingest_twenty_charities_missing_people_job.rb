# The main entry point for ingesting people who are connected to charities
require 'sidekiq-scheduler'

class IngestTwentyCharitiesMissingPeopleJob
  include Sidekiq::Job

  def perform
    # lightweight query to find charities without people (20 at a time to avoid trouble)
    # generally there should not be any charities without people, so this should be a quick job
    charities = Group.find_by(name: 'Charities').groups
    charities_without_people = charities.left_joins(:people).where(people: { id: nil }).limit(20)

    charities_without_people.each do |charity|
      IngestSingleCharitiesPeopleJob.perform_async(charity.id)
    end

  rescue StandardError => e
    Rails.logger.error "Error processing IngestTwentyCharitiesMissingPeopleJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end
end
