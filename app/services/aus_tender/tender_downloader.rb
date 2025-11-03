class AusTender::TenderDownloader
  attr_reader :response

  def download(url)
    # https://app.swaggerhub.com/apis/austender/ocds-api/1.1#/
    conn = Faraday.new(url:)

    @response = conn.get do |req|
      req.params['pretty'] = true
    end

    if success
      body = JSON.parse(response.body)

      {
        success:,
        body:,
        next_page: next_page(body)
      }
    else
      {
        success:,
        status:,
        body: "#{response&.reason_phrase} #{response&.headers['x-cache']}"
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

  def success
    return false unless response

    response&.success? || response&.success || response[:success]
  end

  def status
    return unless response

    response&.status || response[:status]
  end
end