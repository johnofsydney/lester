require 'sidekiq-scheduler'

class ResetAusTenderCrawlbaseJob
  include Sidekiq::Job

  def perform
    AusTenderScraperSwitch.use_plain_scraping
  end
end
