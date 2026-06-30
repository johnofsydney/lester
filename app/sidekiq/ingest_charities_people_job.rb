# The main entry point for ingesting people who are connected to charities
# As of 1/7/2026 there are 64_897 charity groups.
# Each IngestSingleCharitiesPeopleJob can take up to a minute
# Which is about 1100 hours
# At the standard concurrency of 5, and with perfect efficiency this is about 9 days of continuous working
# For a real production system, I'd make these jobs land in a queue with much higher concurrency
# For this project, 9 days is fine really.
# But it is important not to let 64_897 jobs sit inthe queue waiting to process, which is why the check-queue-size-before-proceeding is implemented.
require 'sidekiq-scheduler'

class IngestCharitiesPeopleJob
  # If required, run from console with:
  # IngestCharitiesPeopleJob.perform_async
  include Sidekiq::Job

  QUANTITY = 2_000
  DELAY_IN_MINUTES = 5.minutes

  attr_reader :offset

  def perform(offset = 0)
    @offset = offset.to_i

    if queue_size > QUANTITY
      self.class.perform_in(DELAY_IN_MINUTES, offset)
      return
    end

    groups_to_update.offset(offset).limit(QUANTITY).find_each do |group|
      IngestSingleCharitiesPeopleJob.perform_async(group.id)
    end

    # Re-enqueue itself until fully done
    self.class.perform_in(DELAY_IN_MINUTES, new_offset) if more_remaining?
  end

  def groups_to_update
    Group.find_by(name: 'Charities') # Category / Tag
         .groups
         .with_business_number
         .order(:id)
  end

  def more_remaining?
    groups_to_update.offset(new_offset).exists?
  end

  def new_offset = offset + QUANTITY

  def queue_size
    Sidekiq::Queue.new('low').size
  end
end
