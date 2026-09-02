require 'sidekiq-scheduler'

class Cache::NodeCountJob
  include Sidekiq::Job

  sidekiq_options(
    lock: :until_executed,
    on_conflict: :log,
    retry: 1
  )

  def perform(klass, id)
    node = klass.constantize.find(id)
    count = node.nodes.count

    node.update(nodes_count_cached: count, nodes_count_cached_at: Time.current)
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Cache::NodeCountJob: record not found for #{klass} #{id}: #{e.message}"
    # Don't re-raise - this won't be fixed by retrying
  end
end
