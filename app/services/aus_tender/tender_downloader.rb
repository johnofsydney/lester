class AusTender::TenderDownloader
  def download(url)
    # https://app.swaggerhub.com/apis/austender/ocds-api/1.1#/
    conn = Faraday.new(url:)

    response = conn.get do |req|
      req.params['pretty'] = true
    end

    if response.success?
      body = JSON.parse(response.body)

      {
        success: response.success?,
        body: body,
        next_page: next_page(body)
      }
    else
      {
        success: response.success?,
        status: response.status,
        body: "#{response.reason_phrase} #{response.headers['x-cache']}"
      }
    end
  end

  def next_present?(body)
    body['links'] && body['links']['next'].present?
  end

  def next_page(body)
    return unless next_present?(body)

    body['links']['next']
  end
end