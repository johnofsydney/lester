# Parses the NSW state election LC statewide winners page
# (https://pastvtr.elections.nsw.gov.au/SG<event_id>/LC/state/candidates_elected) -- one row per
# elected member: a leading count column, then Candidate Name | Group | Group Name | Elected at
# Count. Unlike LA, there is no per-seat "elected" page -- LC is a proportional, multi-member,
# group-ticket system, so this statewide roster (21 rows for SG2301) is the only winners source.
class NswStatePoliticians::Lc::CandidatesElectedPageParser
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
    return nil if cells.size < 5

    { name: cells[1], group_letter: cells[2], party: cells[3], elected_at_count: cells[4] }
  end
end
