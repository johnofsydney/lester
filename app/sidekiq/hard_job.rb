class HardJob
  include Sidekiq::Job

  def perform(*args)
    Rails.logger.debug '%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
    Rails.logger.debug args
    Rails.logger.debug '%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
  end
end
