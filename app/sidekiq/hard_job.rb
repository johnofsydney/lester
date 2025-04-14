class HardJob
  include Sidekiq::Job

  def perform(*args)
    p '%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
    p args
    p '%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
  end
end
