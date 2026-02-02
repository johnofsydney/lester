class Discovery::Website::PageDownloader

  def call(url)
    conn = Faraday.new(url:)
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
