class AuAecDonations::Downloader::Base
  BASE_URL = 'https://transparency.aec.gov.au'.freeze

  def call
    # 1. Visit the First page to get the __RequestVerificationToken and cookie
    # 2. Make a POST request to Second page, including the token and cookie and any filters, to get the donations data

    conn = Faraday.new(url: base_url, headers: default_headers)

    first_page_response = conn.get(first_page_path)
    token = request_verification_token(first_page_response.body)
    raise 'Unable to find __RequestVerificationToken on First Page page' if token.blank?

    cookie = cookie_header_value(first_page_response.headers)
    raise 'Unable to find cookie header from First Page response' if cookie.blank?

    response = conn.post(second_page_path) do |req|
      req.params = donations_made_read_params
      req.headers['Cookie'] = cookie
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
      req.headers['X-Requested-With'] = 'XMLHttpRequest'
      req.headers['Referer'] = "#{base_url}#{first_page_path}"
      req.body = URI.encode_www_form(__RequestVerificationToken: token)
    end

    raise "AEC DonationsMadeRead request failed (status #{response.status})" unless response.success?

    JSON.parse(response.body)['Data']
  end

  private

  def default_headers
    {
      'Accept' => 'application/json, text/plain, */*',
      'Origin' => base_url,
      'User-Agent' => 'Mozilla/5.0'
    }
  end

  def request_verification_token(html)
    html[/name="__RequestVerificationToken"\s+type="hidden"\s+value="([^"]+)"/, 1]
  end

  def cookie_header_value(headers)
    raw = headers['set-cookie']
    return if raw.blank?

    Array(raw).flat_map { |entry| entry.split(/,(?=\s*[^;]+=)/) }
              .map { |entry| entry.split(';').first }
              .join('; ')
  end

  def donations_made_read_params
    {
      page: 1,
      pageSize: 1_000_000 # set a very high page size to attempt to get all donations in one request
    }
  end

  def base_url = BASE_URL

  def first_page_path
    raise NotImplementedError, 'Subclasses of AuAecDonations::Downloader::Base must implement the first_page_path method'
  end

  def second_page_path
    raise NotImplementedError, 'Subclasses of AuAecDonations::Downloader::Base must implement the second_page_path method'
  end
end
