# Parses the NSW state election LC "Party or Group and Candidates Result Report"
# (https://pastvtr.elections.nsw.gov.au/SG<event_id>/LC/state/fp_grp_and_candidates) -- a nested
# table: one header row per ballot group (Group letter populated, rest blank), followed by one row
# per candidate in that group (Group cell blank, then Candidate Name | ELECTED/EXCLUDED | Position
# | Count). This is every LC candidate, winner and loser alike, with an explicit status -- unlike
# fp_summary's vote/quota table, no vote-count parsing is needed to find them.
class NswStatePoliticians::Lc::GrpAndCandidatesParser
  def self.call(page) = new(page).call

  def initialize(page)
    @page = page
  end

  def call
    rows = Nokogiri::HTML(page).css('div.prcc-data table tbody tr')
    @current_group_letter = nil

    rows.filter_map { |row| candidate_from(row) }
  end

  private

  attr_reader :page, :current_group_letter

  def candidate_from(row)
    cells = row.css('td').map { |td| td.text.strip }
    return nil if cells.size < 5

    if cells[0].present?
      @current_group_letter = cells[0]
      return nil
    end

    return nil if cells[1].blank?

    { name: cells[1], group_letter: current_group_letter, status: cells[2], position: cells[3], count: cells[4] }
  end
end
