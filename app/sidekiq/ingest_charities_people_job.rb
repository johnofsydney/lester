# The main entry point for ingesting people who are connected to charities
require 'sidekiq-scheduler'

class IngestCharitiesPeopleJob
  include Sidekiq::Job

  SECTIONS = 30

  def perform
    scope = Group.where(name: "Charities")
    total = scope.count
    section_size = (total.to_f / SECTIONS).ceil

    day = Date.today.day
    section_number = ((day - 1) % SECTIONS)

    offset = section_number * section_size

    groups_today = scope.offset(offset).limit(section_size)


    # Group.find_by(name: 'Charities').groups.find_each do |charity|
    groups_today.find_each(batch_size: 100) do |group|
      next unless group&.business_number

      IngestSingleCharitiesPeopleJob.perform_async(group.id)
    end

  rescue StandardError => e
    Rails.logger.error "Error processing charities people: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end
end
