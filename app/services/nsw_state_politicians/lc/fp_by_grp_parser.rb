# Parses the NSW state election LC statewide "group and party name" report
# (https://pastvtr.elections.nsw.gov.au/SG<event_id>/LC/state/fp_by_grp) -- one row per ballot
# group: Group letter | Group/Party Name | vote columns (ignored here). This is the only page that
# maps every ballot group letter to its declared party name, including groups that elected nobody
# -- candidates_elected only ever lists groups that won a seat. Blank-party rows (ungrouped
# independents, which have a letter but no declared party name) and the trailing summary rows
# ("UNGROUPED CANDIDATES", "Total Formal Votes", etc, which all have a blank Group cell) are both
# excluded -- there's nothing for Councils::PartyMapper to resolve either way.
class NswStatePoliticians::Lc::FpByGrpParser
  def self.call(page) = new(page).call

  def initialize(page)
    @page = page
  end

  def call
    Nokogiri::HTML(page).css('div.prcc-data table tbody tr').filter_map { |row| group_from(row) }.to_h
  end

  private

  attr_reader :page

  def group_from(row)
    cells = row.css('td').map { |td| td.text.strip }
    return nil if cells.size < 2
    return nil if cells[0].blank? || cells[1].blank?

    [cells[0], cells[1]]
  end
end
