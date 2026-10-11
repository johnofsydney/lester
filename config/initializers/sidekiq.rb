require "sidekiq-unique-jobs"
require "sidekiq-scheduler/web"  # Add web UI for scheduler

# Isolates test runs from whatever REDIS_URL dev/production use, so Sidekiq::Queue,
# SidekiqUniqueJobs locks, etc. can't read or write real dev data when they bypass
# Sidekiq::Testing.fake! (see spec/rails_helper.rb).
sidekiq_redis_url = Rails.env.test? ? "redis://localhost:6379/15" : ENV["REDIS_URL"]

Sidekiq.configure_server do |config|
  config.redis = { url: sidekiq_redis_url, timeout: 30 }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.redis = { url: sidekiq_redis_url, timeout: 30 }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end
