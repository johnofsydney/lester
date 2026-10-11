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
      next unless row

      parsed = headers.zip(row.map { |cell| json_safe(cell) }).to_h
      # A row with no GA ID is not a real grant -- either a blank trailing row, or the
      # literal "There are no results that match your selection." row GrantConnect
      # returns in place of data on a day with zero published grants.
      next if parsed['GA ID'].blank?

      parsed
    end
  end

  private

  # Job arguments must be native JSON types (Sidekiq.strict_args!) -- Roo returns
  # Date/Time objects for date cells, which aren't valid job arguments.
  def json_safe(cell)
    cell.is_a?(Date) || cell.is_a?(Time) ? cell.iso8601 : cell
  end
end
