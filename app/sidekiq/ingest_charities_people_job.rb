# The main entry point for ingesting people who are connected to charities
require 'sidekiq-scheduler'

class IngestCharitiesPeopleJob
  include Sidekiq::Job

  def perform
    return unless charity_groups_to_fetch.any?

    if queue_size > 100
      Rails.logger.warn "Queue size is too large (#{queue_size}), deferring job"
      self.class.perform_in(5.minutes)
      return
    end

    charity_groups_to_fetch.find_each do |group|
      IngestSingleCharitiesPeopleJob.perform_async(group.id)
    end

    # Re-enqueue itself until fully done
    self.class.perform_in(5.minutes)

  rescue StandardError => e
    Rails.logger.error "Error processing charities people: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(message: e.message)
    raise e
  end

  def charity_groups_to_fetch
    batch_size = 50

    Group.find_by(name: "Charities").groups
                                    .with_business_number
                                    .can_refresh
                                    .limit(batch_size)
  end

  def queue_size
    Sidekiq::Queue.new('low').size
  end
end
