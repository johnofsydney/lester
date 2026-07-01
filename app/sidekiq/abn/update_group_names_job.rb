require 'sidekiq-scheduler'

class Abn::UpdateGroupNamesJob
  include Sidekiq::Job

  sidekiq_options(
    lock: :until_executed,
    on_conflict: :log,
    retry: 1
  )

  def perform(id)
    group = Group.find(id)
    Abn::GroupNameUpdater.call(group)
  end
end
