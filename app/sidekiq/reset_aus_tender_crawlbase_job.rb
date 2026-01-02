require 'sidekiq-scheduler'

class ResetAusTenderCrawlbaseJob
  include Sidekiq::Job

  def perform
    Circuit::AusTenderScraperSwitch.use_plain_scraping
  end
end
