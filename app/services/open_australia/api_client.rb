class OpenAustralia::ApiClient
  BASE_URL = 'https://www.openaustralia.org.au/api/'.freeze

  def get_representatives(date: nil)
    get('getRepresentatives', date:)
  end

  def get_senators(date: nil)
    get('getSenators', date:)
  end

  def get_representative(person_id)
    get('getRepresentative', id: person_id)
  end

  def get_senator(person_id)
    get('getSenator', id: person_id)
  end

  private

  def get(function, params = {})
    response = connection.get(function, base_params.merge(params.compact))
    raise "OpenAustralia API error (#{response.status}): #{response.body.truncate(200)}" unless response.success?

    JSON.parse(response.body)
  end

  def base_params
    { key: api_key, output: 'js' }
  end

  def api_key
    Rails.application.credentials.dig(:open_australia, :api_key)
  end

  def connection
    @connection ||= Faraday.new(url: BASE_URL)
  end
end
