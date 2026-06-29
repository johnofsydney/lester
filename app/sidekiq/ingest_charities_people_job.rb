# The main entry point for ingesting people who are connected to charities
require 'sidekiq-scheduler'

class IngestCharitiesPeopleJob
  # If required, run from console with:
  # IngestCharitiesPeopleJob.perform_async
  include Sidekiq::Job

  QUANTITY = 2_000

  attr_reader :offset

  def perform(offset = 0)
    @offset = offset.to_i

    groups_to_update.offset(offset).limit(QUANTITY).find_each do |group|
      IngestSingleCharitiesPeopleJob.perform_async(group.id)
    end

    # Re-enqueue itself until fully done
    self.class.perform_in(4.minutes, offset + QUANTITY) if more_remaining?
  end

  def groups_to_update
    Group.find_by(name: 'Charities').groups.with_business_number.order(:id)
  end

  def more_remaining?
    groups_to_update.offset(offset + QUANTITY).exists?
  end
end
