class Cache::BuildGroupCachedDataJob
  include Sidekiq::Job

  sidekiq_options queue: :critical, lock: :until_executed, on_conflict: :log

  def perform(id)
    group = Group.find_by(id:)
    return unless group

    Rails.logger.info "Building cached data for Group #{group.name} (ID: #{group.id})"

    group.refresh_cached_data!
  end
end
