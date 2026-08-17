# Parses a NSW Electoral Commission council results page
# (https://pastvtr.elections.nsw.gov.au/LG<election_id>/<slug>/results) into the
# relative councillor-contest path(s) for that council -- a single "councillor" path
# for councils elected at-large, or one "ward-x/councillor" path per ward for councils
# divided into wards. Deliberately ignores any separate "Mayor:" contest row -- direct
# mayoral elections are out of scope for this phase.
class Councils::Nsw::ResultsPageParser
  COUNCILLOR_LINK_HREF = %r{\A/LG\d+/[a-z0-9-]+/(.+)\z}

  # Two confirmed reasons a NSWEC results page has no contest table at all, just prose instead --
  # neither is a parsing problem, both mean "nothing for this pipeline to record":
  # - A council placed in administration for that cycle holds no election at all (e.g.
  #   Balranald's LG2101/2021 page). Not permanent -- a council can hold its next election
  #   normally once administration ends (confirmed: Balranald did in 2024).
  # - A council that has opted to conduct its own election under s296 of the Local Government
  #   Amendment (Elections) Act 2011 is never on NSWEC's site at all, in any cycle (confirmed
  #   live for Fairfield in both LG2101/2021 and LG2401/2024, and Penrith/Liverpool in one cycle
  #   each) -- this pipeline has no source for these councils' results.
  # A full live scan across all 128 NSW councils (both cycles) found no other page shape lacking
  # a contest table -- anything else is presumed a genuine unexpected/empty page and still raises.
  NO_CONTEST_REGEX = /has been placed in administration|chosen to conduct its own election/i

  def self.call(page)
    new(page).call
  end

  def self.no_contest_expected?(page)
    page.to_s.match?(NO_CONTEST_REGEX)
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
