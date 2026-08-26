# Parses a NSW Electoral Commission council results page
# (https://pastvtr.elections.nsw.gov.au/LG<election_id>/<slug>/results) into the
# relative contest path(s) for that council, each tagged with the title to record the
# contest's winner(s) under -- a single "councillor" path for councils elected at-large,
# or one "ward-x/councillor" path per ward for councils divided into wards (title:
# 'Councillor'), plus a "Mayor:" row's path when present (title: 'Mayor'). Most NSW
# councils elect their mayor from among councillors rather than directly, and simply
# have no "Mayor:" row at all in that case -- there is no other page shape to detect for
# "no separate mayoral contest".
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
    contests_for_row('Councillors:', title: 'Councillor') + contests_for_row('Mayor:', title: 'Mayor')
  end

  private

  attr_reader :page

  def doc
    @doc ||= Nokogiri::HTML(page)
  end

  def contests_for_row(label, title:)
    row = row_labelled(label)
    return [] if row.nil?

    row.css('a.contest[href]').filter_map { |link| contest_path(link) }.map { |path| { path:, title: } }
  end

  def row_labelled(label)
    doc.css('tr').find do |row|
      row.at_css('td')&.text&.strip == label
    end
  end

  def contest_path(link)
    match = link['href'].to_s.match(COUNCILLOR_LINK_HREF)
    match && match[1]
  end
end
