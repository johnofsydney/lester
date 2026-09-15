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
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Abn::UpdateGroupNamesJob: Group #{id} not found: #{e.message}"
    # Don't re-raise - this won't be fixed by retrying
  end
end
