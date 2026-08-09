# Parses a NSW Electoral Commission council results page
# (https://pastvtr.elections.nsw.gov.au/LG<election_id>/<slug>/results) into the
# relative councillor-contest path(s) for that council -- a single "councillor" path
# for councils elected at-large, or one "ward-x/councillor" path per ward for councils
# divided into wards. Deliberately ignores any separate "Mayor:" contest row -- direct
# mayoral elections are out of scope for this phase.
class Councils::Nsw::ResultsPageParser
  COUNCILLOR_LINK_HREF = %r{\A/LG\d+/[a-z0-9-]+/(.+)\z}

  def self.call(page)
    new(page).call
  end

  def initialize(page)
    @page = page
  end

  def call
    row = councillors_row
    return [] if row.nil?

    row.css('a.contest[href]').filter_map { |link| councillor_path(link) }
  end

  private

  attr_reader :page

  def councillors_row
    Nokogiri::HTML(page).css('tr').find do |row|
      row.at_css('td')&.text&.strip == 'Councillors:'
    end
  end

  def councillor_path(link)
    match = link['href'].to_s.match(COUNCILLOR_LINK_HREF)
    match && match[1]
  end
end
