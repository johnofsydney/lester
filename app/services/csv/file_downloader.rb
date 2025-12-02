require "faraday"
require "json"

class Csv::FileDownloader
  def perform

    conn = Faraday.new(
      url: "https://api.lobbyists.ag.gov.au",
      headers: {
        "Content-Type" => "application/json",
        "Accept" => "application/json, text/plain, */*",
        "Origin" => "https://lobbyists.ag.gov.au",
        "Referer" => "https://lobbyists.ag.gov.au/",
        # User-Agent optional but safest
        "User-Agent" => "Mozilla/5.0"
      }
    )

    payload = {
      fileExtension: "csv",
      searchCriteria: {
        entity: "all",
        query: "",
        pageNumber: 1,
        pagingCookie: nil,
        count: 10,
        sortCriteria: { fieldName: "", sortOrder: 0 },
        isDeregistered: false
      }
    }

    response = conn.post("/search/download", payload.to_json)

    # Verify it worked
    if response.success?
      # The API returns raw CSV content in the body
      path = Rails.root.join("tmp", "lobbyists.xlsx")
      # write as binary so Ruby doesn't try to transcode
      File.open(path, "wb") do |f|
        f.write(response.body)
      end

      puts "Downloaded lobbyists.xlsx (#{response.body.bytesize} bytes)"
    else
      puts "Error #{response.status}: #{response.body}"
    end
  end
end
