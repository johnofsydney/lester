class OpenAustraliaApiError < StandardError; end

class OpenAustralia::ApiClient
  BASE_URL = 'https://www.openaustralia.org.au/api/'.freeze

  def get_representative(person_id)
    get('getRepresentative', id: person_id)
  end

  def get_senator(person_id)
    get('getSenator', id: person_id)
  end

  # Names mirror the OpenAustralia API's own action names (getRepresentatives/getSenators),
  # not Ruby accessor conventions.
  # rubocop:disable Naming/AccessorMethodName
  def get_representatives
    get('getRepresentatives')
  end

  def get_senators
    get('getSenators')
  end
  # rubocop:enable Naming/AccessorMethodName

  private

  def get(action, params = {})
    response = connection.get(action, params.merge(key: api_key, output: 'js'))
    raise OpenAustraliaApiError, "#{response.status}: #{response.body}" unless response.success?

    JSON.parse(response.body)
  end

  def connection
    @connection ||= Faraday.new(url: BASE_URL)
  end

  def api_key
    Rails.application.credentials.dig(:open_australia, :api_key)
  end
end
