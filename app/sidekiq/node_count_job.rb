require 'sidekiq-scheduler'

class NodeCountJob
  include Sidekiq::Job

  sidekiq_options(
    lock: :until_executed,
    on_conflict: :log,
    retry: 1
  )

  include Sidekiq::Job

  def perform(klass, id)
    node = klass.constantize.find(id)
    count = node.nodes.count

    node.update(nodes_count_cached: count, nodes_count_cached_at: Time.current)
  end
end
