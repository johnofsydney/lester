class SidekiqUtils
  def self.queue_size(queue_name)
    Sidekiq::Queue.new(queue_name).size
  end

  def self.scheduled_size(queue_name)
    Sidekiq::ScheduledSet.new.select { |job| job.queue == queue_name }.size
  end

  def self.retry_size(queue_name)
    Sidekiq::RetrySet.new.select { |job| job.queue == queue_name }.size
  end

  def self.already_scheduled?(klass_name)
    Sidekiq::ScheduledSet.new.any? do |job|
      job.klass == klass_name
    end
  end

  def self.clear_scheduled_jobs
    Sidekiq::ScheduledSet.new.clear
  end

  def self.set_redis_key(key, value)
    Sidekiq.redis { |r| r.set(key, value) }
  end

  def self.get_redis_key(key)
    Sidekiq.redis { |r| r.get(key) }
  end

  def self.delete_redis_key(key)
    Sidekiq.redis { |r| r.del(key) }
  end
end