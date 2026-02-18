class Circuit::AusTenderScraperSwitch
  def self.use_plain_scraping!
    Rails.logger.info 'Switched to Plain scraping'
    SidekiqUtils.delete_redis_key('aus_tender_use_crawlbase')
  end

  def self.use_crawlbase_scraping!
    return if SidekiqUtils.get_redis_key('aus_tender_use_crawlbase') == 'true'

    Rails.logger.info 'Switched to Crawlbase scraping'

    SidekiqUtils.set_redis_key('aus_tender_use_crawlbase', 'true')
    ResetAusTenderCrawlbaseJob.perform_in(1.minute) unless SidekiqUtils.already_scheduled?('ResetAusTenderCrawlbaseJob')
  end
end