class AuAecDonations::Downloader::AnnualDonations
  BASE_URL = 'https://transparency.aec.gov.au'.freeze
  ANNUAL_DONOR_PATH = '/AnnualDonor'.freeze
  DONATIONS_MADE_READ_PATH = '/AnnualDonor/DonationsMadeRead'.freeze

  def self.call(financial_year)
    new(financial_year).call
  end

  def initialize(financial_year)
    raise unless financial_year.is_a?(String) && financial_year.match?(/^\d{4}-\d{2}$/)

    @financial_year = financial_year
  end

  attr_reader :financial_year

  def call
    # 1. Visit the Annual Donor page to get the __RequestVerificationToken and cookie
    # 2. Make a POST request to DonationsMadeRead with the financial year filter, including the token and cookie, to get the donations data for that year

    conn = Faraday.new(url: BASE_URL, headers: default_headers)

    annual_donor_page_response = conn.get(ANNUAL_DONOR_PATH)
    token = request_verification_token(annual_donor_page_response.body)
    raise 'Unable to find __RequestVerificationToken on AnnualDonor page' if token.blank?

    cookie = cookie_header_value(annual_donor_page_response.headers)
    raise 'Unable to find cookie header from AnnualDonor response' if cookie.blank?

    response = conn.post(DONATIONS_MADE_READ_PATH) do |req|
      req.params = donations_made_read_params
      req.headers['Cookie'] = cookie
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
      req.headers['X-Requested-With'] = 'XMLHttpRequest'
      req.headers['Referer'] = "#{BASE_URL}#{ANNUAL_DONOR_PATH}"
      req.body = URI.encode_www_form(__RequestVerificationToken: token)
    end

    raise "AEC DonationsMadeRead request failed (status #{response.status})" unless response.success?

    JSON.parse(response.body)['Data']
  end

  private

  def default_headers
    {
      'Accept' => 'application/json, text/plain, */*',
      'Origin' => BASE_URL,
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
      pageSize: 1_000_000, # set a very high page size to attempt to get all donations in one request
      filter: "FinancialYear~eq~'#{financial_year}'"
    }
  end
end
