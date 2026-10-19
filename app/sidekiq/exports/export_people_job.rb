class Exports::ExportPeopleJob
  include Sidekiq::Job

  sidekiq_options queue: :low

  QUANTITY = 500
  DELAY_IN_MINUTES = 5.minutes

  attr_reader :offset

  def perform(offset = 0)
    @offset = offset.to_i

    if queue_size > QUANTITY
      self.class.perform_in(DELAY_IN_MINUTES, offset)
      return
    end

    people_to_refresh.offset(offset).limit(QUANTITY).find_each(&:refresh_cached_data!)

    # Re-enqueue itself until fully done
    self.class.perform_in(DELAY_IN_MINUTES, new_offset) if more_remaining?
  end

  private

  def people_to_refresh
    Person.cache_stale.order(:id)
  end

  def people_remaining?
    people_to_refresh.offset(new_offset).exists?
  end

  def more_remaining? = people_remaining?

  def new_offset = offset + QUANTITY

  def queue_size
    Sidekiq::Queue.new('low').size
  end
end
