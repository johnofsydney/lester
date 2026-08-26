# Parses a Victorian Electoral Commission council results page
# (https://www.vec.vic.gov.au/results/council-election-results/<year>-council-election-results/<slug>)
# into the elected candidates (each tagged with the title to record them under) and the date the
# page was last updated, or nil when there's no "Elected candidates" section yet (results not
# finalised).
#
# A council's page holds one "Elected candidates" section per contest -- a single
# section for an unsubdivided council, one per ward for a ward-divided council, or
# (for a handful of councils, e.g. Melbourne) a separate directly-elected "Leadership
# Team" contest -- one contest electing both a Lord Mayor and a Deputy Lord Mayor --
# alongside the "Councillors" contest. Every section shares one page-level "Last
# updated" timestamp.
#
# Unlike NSW, VEC results pages don't show party/group affiliation, so only names
# are captured here.
class Councils::Vic::CouncillorResultsParser
  LAST_UPDATED_REGEX = /Last updated: \w+, (\d{1,2} \w+ \d{4})/
  ELECTED_SUFFIX_REGEX = /\s*\(\s*\S+\s+elected\s*\)\s*\z/im
  LEADERSHIP_TEAM_REGEX = /\ALeadership Team\b/i
  LEADERSHIP_ROLE_REGEX = /\A(.+?)\s*\(\s*(Lord Mayor|Deputy Lord Mayor)\s*\)\s*\z/i
  ELECTED_CANDIDATES_HEADING = 'Elected candidates'.freeze

  def self.call(page)
    new(page).call
  end

  def initialize(page)
    @page = page
  end

  def call
    doc = Nokogiri::HTML(page)

    contests = elected_candidates_contests(doc)
    return nil if contests.empty?

    declared_date = parse_last_updated(doc)
    return nil if declared_date.nil?

    { declared_date:, candidates: contests.flat_map { |contest| candidates(contest) } }
  end

  private

  attr_reader :page

  def elected_candidates_contests(doc)
    doc.xpath("//h3[normalize-space(text())='#{ELECTED_CANDIDATES_HEADING}']").filter_map do |heading|
      table = heading.xpath('following::table[contains(@class, "multicolumn-results-table")]').first
      next nil if table.nil?

      { table:, leadership_team: leadership_team_contest?(heading) }
    end
  end

  # A contest's title is the nearest preceding h2/h3 heading that isn't itself an
  # "Elected candidates" heading -- e.g. "Akoonah Ward (1 vacancy)" or "Leadership
  # Team (election of 1 Lord Mayor and 1 Deputy Lord Mayor)".
  def leadership_team_contest?(elected_heading)
    title = elected_heading.xpath(
      "preceding::h2 | preceding::h3[normalize-space(text()) != '#{ELECTED_CANDIDATES_HEADING}']"
    ).last&.text.to_s

    title.match?(LEADERSHIP_TEAM_REGEX)
  end

  def parse_last_updated(doc)
    text = doc.text
    match = text.match(LAST_UPDATED_REGEX)
    return nil if match.nil?

    Date.parse(match[1])
  end

  def candidates(contest)
    contest[:table].css('td.list-item-body').filter_map do |cell|
      if contest[:leadership_team]
        leadership_candidate(cell.text)
      else
        councillor_candidate(cell.text)
      end
    end
  end

  def councillor_candidate(raw_text)
    name = clean_name(raw_text)
    return nil if name.blank?

    { name:, party: '', title: 'Councillor' }
  end

  # A Leadership Team contest elects two distinct roles at once -- each candidate's row names
  # their specific role (e.g. "REECE, Nick (Lord Mayor)") rather than an ordinal like the
  # "(1st elected)" suffix used elsewhere, so that's what becomes this candidate's title.
  def leadership_candidate(raw_text)
    match = raw_text.strip.match(LEADERSHIP_ROLE_REGEX)
    return nil if match.nil?

    { name: match[1].strip, party: '', title: match[2] }
  end

  def clean_name(raw_text)
    raw_text.strip.sub(ELECTED_SUFFIX_REGEX, '').strip
  end
end
