# Downloads the GrantConnect GaPublishedDownload XLSX for a given date range.
# Requires a two-step request: the show page establishes a session cookie
# that the download endpoint requires.

class AuGrants::GrantsDownloader
  BASE_URL = 'https://www.grants.gov.au'.freeze

  def call(date)
    date_param = date.strftime('%d-%b-%Y')

    conn = Faraday.new(url: BASE_URL) do |f|
      f.use Faraday::Response::RaiseError
    end

    show_response = conn.get('/Reports/GaPublishedShow', published_params(date_param))
    cookie = show_response.headers['set-cookie']

    download_response = conn.get('/Reports/GaPublishedDownload', published_params(date_param)) do |req|
      req.headers['Cookie'] = cookie if cookie
    end

    path = Rails.root.join("tmp/grants_#{date}.xlsx")
    File.binwrite(path, download_response.body)

    path
  end

  private

  def published_params(date_param)
    {
      AgencyStatus: 0,
      DateType: 'Publish Date',
      DateStart: date_param,
      DateEnd: date_param
    }
  end
end
