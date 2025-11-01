require "sidekiq-unique-jobs"
require 'sidekiq-scheduler'
require "sidekiq-scheduler/web"  # Add web UI for scheduler

Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDIS_URL"] }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDIS_URL"] }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

schedule_file =
  if Rails.env.production?
    Rails.root.join('config', 'sidekiq_schedule_production.yml')
  else
    Rails.root.join('config', 'sidekiq_schedule_staging.yml')
  end

if File.exist?(schedule_file)
  Sidekiq.schedule = YAML.load_file(schedule_file) # assign schedule
  Sidekiq::Scheduler.reload_schedule!               # reloads schedule, no args
end