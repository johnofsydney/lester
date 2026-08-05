class Councils::PageDownloader
  USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'.freeze

  def self.call(url)
    new.call(url)
  end

  def call(url)
    conn = Faraday.new(url:) do |config|
      config.headers['User-Agent'] = USER_AGENT
      config.headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      config.options.timeout = 10
      config.options.open_timeout = 10
    end

    response = conn.get

    if response.success?
      response.body
    else
      Rails.logger.warn "Councils::PageDownloader: HTTP #{response.status} for #{url}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Councils::PageDownloader: failed to download #{url}: #{e.message}"
    nil
  end
end
