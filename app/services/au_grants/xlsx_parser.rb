# Parses the GrantConnect GaPublishedDownload XLSX.
# Rows 1-22 are a metadata/criteria summary, row 23 is the header, data starts at row 24.

class AuGrants::XlsxParser
  HEADER_ROW = 23

  def call(path)
    xlsx = Roo::Excelx.new(path)
    sheet = xlsx.sheet(0)
    headers = sheet.row(HEADER_ROW)

    ((HEADER_ROW + 1)..sheet.last_row).filter_map do |r|
      row = sheet.row(r)
      next unless row&.any?

      headers.zip(row).to_h
    end
  end
end
