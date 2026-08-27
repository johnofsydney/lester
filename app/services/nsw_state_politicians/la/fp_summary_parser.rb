# Parses a NSW state election LA electorate first-preference results page
# (https://pastvtr.elections.nsw.gov.au/SG<event_id>/LA/<electorate>/cc/fp_summary) -- one row per
# candidate (winner and unsuccessful), plus a trailing "TOTAL FORMAL VOTES" summary row which is
# not a candidate and is excluded here.
class NswStatePoliticians::La::FpSummaryParser
  TOTAL_ROW_LABEL = /\Atotal formal votes\z/i

  def self.call(page) = new(page).call

  def initialize(page)
    @page = page
  end

  def call
    Nokogiri::HTML(page).css('div.prcc-data table tbody tr').filter_map { |row| candidate_from(row) }
  end

  private

  attr_reader :page

  def candidate_from(row)
    cells = row.css('td').map { |td| td.text.strip }
    return nil if cells.size < 2
    return nil if cells[0].match?(TOTAL_ROW_LABEL)

    { name: cells[0], party: cells[1] }
  end
end
