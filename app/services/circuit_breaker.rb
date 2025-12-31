class CircuitBreaker
  def self.open(queue_name)
    Rails.logger.warn "Circuit breaker opened for queue: #{queue_name}"

    pause_key = "pause:queue:#{queue_name}"  # Sidekiq's internal key for pausing queues (e.g., "pause:queue:aus_tender_contracts")
    Sidekiq.redis { |r| r.set(pause_key, '1') }


    # Schedule a job to close the circuit after a cooldown period
    CircuitBreakerReOpenJob.perform_in(2.minutes, queue_name)
  end
end
