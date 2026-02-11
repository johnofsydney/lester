class AusTender::TenderDownloader
  attr_reader :response

  def download(url)
    # https://app.swaggerhub.com/apis/austender/ocds-api/1.1#/
    conn = Faraday.new(url:)

    @response = conn.get do |req|
      req.params['pretty'] = true
    end

    if success
      { success:, status:, body:, next_page: }
    else
      { success:, status:, body: }
    end
  end

  def next_present?
    body['links'] && body['links']['next'].present?
  end

  def next_page
    return unless next_present?

    body['links']['next']
  end

  def success
    return false unless response

    response&.success? || response[:success]
  end

  def status
    return unless response

    response&.status || response[:status]
  end

  def body
    return unless response

    JSON.parse(response.body)
  end
end