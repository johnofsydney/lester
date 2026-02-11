class AcncCharities::CsvDownloader
  attr_reader :response

  def download(url)
    conn = Faraday.new(url:)

    @response = conn.get do |req|
      req.params['pretty'] = true
    end

    { success:, status:, body: }
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

    response.body
  end
end
