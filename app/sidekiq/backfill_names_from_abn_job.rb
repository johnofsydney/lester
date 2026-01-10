require 'sidekiq-scheduler'

class BackfillNamesFromAbnJob
  # run from console with:
  # BackfillNamesFromAbnJob.perform_async
  # Can delete when finished
  include Sidekiq::Job

  QUANTITY = 1_000

  def perform
    groups_to_update.limit(QUANTITY).find_each do |group|
      UpdateGroupNamesFromAbnJob.perform_async(group.id)
    end

    # Re-enqueue itself until fully done
    self.class.perform_in(5.minutes) if more_remaining?
  end

  def groups_to_update
    Group.where.not(business_number: nil).order(:id)
  end

  def more_remaining?
    groups_to_update.offset(QUANTITY).exists?
  end
end