#  can DELETE after running

class Maintenance::DowncaseAllGroupNamesJob
  include Sidekiq::Job
  sidekiq_options queue: :low, retry: 5

  BATCH_SIZE = 1000

  def perform(offset = 0)
    groups = Group.limit(BATCH_SIZE).offset(offset).to_a
    return if groups.empty?

    groups.each do |group|
      Maintenance::DowncaseSingleGroupNameJob.perform_async(group.id)
    end

    Maintenance::DowncaseAllGroupNamesJob.perform_in(10.seconds, offset + BATCH_SIZE)
  end
end
