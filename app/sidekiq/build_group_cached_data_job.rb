class BuildGroupCachedDataJob
  include Sidekiq::Job

  sidekiq_options queue: :cache_build, lock: :until_executed, on_conflict: :log

  def perform(id)
    group = Group.find_by(id:)
    return unless group

    Rails.logger.info "Building cached data for Group #{group.name} (ID: #{group.id})"

    group.update(cached_summary: group.to_h, cached_summary_timestamp: Time.zone.now)
  rescue StandardError => e
    NewRelic::Agent.notice_error(e) if defined?(NewRelic)
    Rails.logger.error "Error building cached data for Group ID #{id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end