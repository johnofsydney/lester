# This is very specific service to download lobbyist data from the Australian
# Government Lobbyist Register, and convert it from XLSX to CSV files.

class AuLobbyists::FileDownloader
  def perform
    conn = Faraday.new(
      url: "https://api.lobbyists.ag.gov.au",
      headers: {
        "Content-Type" => "application/json",
        "Accept" => "application/json, text/plain, */*",
        "Origin" => "https://lobbyists.ag.gov.au",
        "Referer" => "https://lobbyists.ag.gov.au/",
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

      Rails.logger.info "Downloaded lobbyists.xlsx (#{response.body.bytesize} bytes)"
    else
      Rails.logger.warn "Error #{response.status}: #{response.body}"
      return false
    end

    # Work with the XLSX file using the Roo gem
    xlsx = Roo::Excelx.new(path)

    xlsx.sheets.each do |sheet_name|
      sheet = xlsx.sheet(sheet_name)
      filename = Rails.root.join('tmp', "#{sheet_name.gsub(/\s/, '_').downcase}.csv")

      CSV.open(filename, 'wb') do |csv_out|
        first_row = sheet.first_row || 1
        last_row = sheet.last_row || 0

        # Skip the top 7 rows (i.e. start at row index first_row + 7)
        start_row = first_row + 7

        (start_row..last_row).each do |r|
          row = sheet.row(r)
          next unless row && row.any?

          csv_out << row
        end
      end
    end

    # Remove temporary xlsx file
    begin
      File.delete(path) if path && File.exist?(path)
    rescue => e
      Rails.logger.warn "Csv::FileDownloader: failed to delete temp xlsx #{path}: #{e.class} #{e.message}"
    end

    true
  end
end
