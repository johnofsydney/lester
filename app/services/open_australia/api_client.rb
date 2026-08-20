class OpenAustraliaApiError < StandardError; end
class OpenAustraliaRateLimitError < OpenAustraliaApiError; end

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
    raise OpenAustraliaRateLimitError, "#{response.status}: #{response.body}" if response.status == 429
    raise OpenAustraliaApiError, "#{response.status}: #{response.body}" unless response.success?

    parsed = JSON.parse(response.body)
    # A 200 response can still carry an error payload (e.g. a missing/invalid API key) as a
    # JSON object instead of the expected Array -- surface that clearly here rather than letting
    # every caller hit a confusing NoMethodError further downstream when it tries to treat the
    # object as a list of terms.
    raise OpenAustraliaApiError, "#{action}: #{parsed['error']}" if parsed.is_a?(Hash) && parsed['error']

    parsed
  end

  def connection
    @connection ||= Faraday.new(url: BASE_URL)
  end

  def api_key
    Rails.application.credentials.dig(:open_australia, :api_key)
  end
end
