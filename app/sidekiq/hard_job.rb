require 'sidekiq-scheduler'

class HardJob
  include Sidekiq::Job

  def perform(*args)
    # return unless Flipper.enabled?(:hard_job)
    Rails.logger.debug '%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
    Rails.logger.debug args
    Rails.logger.debug '%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
  end
end
