# The main entry point for ingesting people who are connected to charities
require 'sidekiq-scheduler'

class IngestCharitiesPeopleJob
  include Sidekiq::Job

  def perform
    Group.find_by(name: 'Charities').groups.find_each do |charity|
      next unless charity&.business_number

      IngestSingleCharitiesPeopleJob.perform_async(charity.id)
    end

  rescue StandardError => e
    Rails.logger.error "Error processing charities people: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end
end
