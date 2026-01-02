class Circuit::AusTenderScraperSwitch
  def self.use_plain_scraping
    Current.use_crawlbase_for_aus_tender_scraping = false
  end

  def self.use_crawlbase_scraping
    return if Current.use_crawlbase_for_aus_tender_scraping

    Current.use_crawlbase_for_aus_tender_scraping = true
    ResetAusTenderCrawlbaseJob.perform_in(1.minute) unless reset_already_queued?
  end

  def reset_already_queued?
    Sidekiq::ScheduledSet.new.any? do |job|
      job.klass == 'ResetAusTenderCrawlbaseJob'
    end
  end
end