require 'sidekiq-scheduler'

class Acnc::IngestPeopleJob
  # If required, run from console with:
  # Acnc::IngestPeopleJob.perform_async
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
      Acnc::IngestSingleCharityPeopleJob.perform_async(group.id)
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
