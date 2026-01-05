require 'sidekiq-scheduler'

class ResetAusTenderCrawlbaseJob
  include Sidekiq::Job

  sidekiq_options(
    queue: :critical,
    lock: :until_executed,
    on_conflict: :log,
    retry: 3
  )

  def perform
    Circuit::AusTenderScraperSwitch.use_plain_scraping!
  end
end
