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

  def self.clear_scheduled_jobs(klass_name)
    Sidekiq::ScheduledSet.new.clear
  end
end