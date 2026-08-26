# Parses the NSW state election LA statewide winners page
# (https://pastvtr.elections.nsw.gov.au/SG<event_id>/LA/state/elected) -- one row per electorate:
# District | Candidate | Representation (party). This is the full winners roster in one page fetch.
class NswStatePoliticians::La::ElectedPageParser
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
    return nil if cells.size < 3

    { electorate: cells[0], name: cells[1], party: cells[2] }
  end
end
