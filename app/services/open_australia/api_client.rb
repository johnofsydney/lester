class OpenAustraliaApiError < StandardError; end
class OpenAustraliaRateLimitError < OpenAustraliaApiError; end

class OpenAustralia::ApiClient
  BASE_URL = 'https://www.openaustralia.org.au/api/'.freeze

  # get_representative/get_senator respond with an error-shaped JSON object (e.g.
  # {"error" => "Unknown person ID"}) for any id with no data in that chamber -- that's the
  # expected, common outcome when sweeping a wide id range (Increment 4's historical backfill),
  # not a real failure, so it's allowed to flow through unparsed here. IngestPerson's
  # coerce_to_array already treats any non-Array response as "no terms".
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
    get('getRepresentatives', expect_array: true)
  end

  def get_senators
    get('getSenators', expect_array: true)
  end
  # rubocop:enable Naming/AccessorMethodName

  private

  def get(action, params = {})
    expect_array = params.delete(:expect_array)
    response = connection.get(action, params.merge(key: api_key, output: 'js'))
    raise OpenAustraliaRateLimitError, "#{response.status}: #{response.body}" if response.status == 429
    raise OpenAustraliaApiError, "#{response.status}: #{response.body}" unless response.success?

    parsed = JSON.parse(response.body)
    # A 200 response can still carry an error payload (e.g. a missing/invalid API key) as a
    # JSON object instead of the expected Array -- surface that clearly here rather than letting
    # the roster callers hit a confusing NoMethodError further downstream when they try to treat
    # the object as a list. Only applies where an Array is actually expected (the roster
    # endpoints) -- per-person lookups legitimately return an error object for unknown ids.
    raise OpenAustraliaApiError, "#{action}: #{parsed['error']}" if expect_array && parsed.is_a?(Hash) && parsed['error']

    parsed
  end

  def connection
    @connection ||= Faraday.new(url: BASE_URL)
  end

  def api_key
    Rails.application.credentials.dig(:open_australia, :api_key)
  end
end
