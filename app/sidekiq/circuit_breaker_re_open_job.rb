class CircuitBreakerReOpenJob
  include Sidekiq::Job

  sidekiq_options queue: :critical, retry: 3

  def perform(queue_name)
    pause_key = "pause:queue:#{queue_name}"  # Sidekiq's internal key for pausing queues (e.g., "pause:queue:aus_tender_contracts")
    Sidekiq.redis { |r| r.del(pause_key) }  # Unpause the queue
  end
end
