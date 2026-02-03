class Discovery::Website::PageDownloader

  def self.call(url)
    new.call(url)
  end

  def call(url)
    conn = Faraday.new(url:) do |config|
        config.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'
        config.headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'

      # Set timeout values (too big for normal use)
      config.options.timeout = 90        # 90 seconds for read timeout
      config.options.open_timeout = 30   # 30 seconds for connection timeout
    end
    response = conn.get

    if response.success?
      response.body
    else
      Rails.logger.warn "Error #{response.status} when downloading #{url}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error("Failed to download page: #{e.message}")
    nil
  end
end
