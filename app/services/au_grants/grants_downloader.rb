# Downloads the GrantConnect GaPublishedDownload XLSX for a given date range.
# Requires a two-step request: the show page establishes a session cookie
# that the download endpoint requires.

class AuGrants::GrantsDownloader
  BASE_URL = 'https://www.grants.gov.au'.freeze

  def call(date)
    date_param = date.strftime('%d-%b-%Y')

    conn = Faraday.new(
      url: BASE_URL,
      headers: {
        'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36',
        'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      }
    ) do |f|
      f.use Faraday::Response::RaiseError
    end

    show_response = conn.get('/Reports/GaPublishedShow', published_params(date_param))
    cookie = session_cookie(show_response.headers['set-cookie'])

    download_response = conn.get('/Reports/GaPublishedDownload', published_params(date_param)) do |req|
      req.headers['Cookie'] = cookie if cookie
    end

    path = Rails.root.join("tmp/grants_#{date}.xlsx")
    File.binwrite(path, download_response.body)

    path
  end

  private

  # Faraday joins multiple Set-Cookie response headers into one comma-separated
  # string; the Cookie request header needs just "name=value" pairs, semicolon-separated.
  def session_cookie(set_cookie_header)
    return nil if set_cookie_header.blank?

    set_cookie_header.split(', ').map { |part| part.split(';').first }.join('; ')
  end

  def published_params(date_param)
    {
      AgencyStatus: 0,
      DateType: 'Publish Date',
      DateStart: date_param,
      DateEnd: date_param
    }
  end
end
