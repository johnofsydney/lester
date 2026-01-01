# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :host, :use_crawlbase_for_aus_tender_scraping

  def local_host?
    host.match?(/localhost/)
  end
end