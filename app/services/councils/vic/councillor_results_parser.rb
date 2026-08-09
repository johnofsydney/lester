# Parses a Victorian Electoral Commission council results page
# (https://www.vec.vic.gov.au/results/council-election-results/<year>-council-election-results/<slug>)
# into the elected candidates and the date the page was last updated, or nil when
# there's no "Elected candidates" section yet (results not finalised).
#
# A council's page holds one "Elected candidates" section per contest -- a single
# section for an unsubdivided council, one per ward for a ward-divided council, or
# (for a handful of councils, e.g. Melbourne) a separate directly-elected "Leadership
# Team" (Lord Mayor/Deputy Lord Mayor) contest alongside the "Councillors" contest.
# Every section shares one page-level "Last updated" timestamp.
#
# Unlike NSW, VEC results pages don't show party/group affiliation, so only names
# are captured here.
class Councils::Vic::CouncillorResultsParser
  LAST_UPDATED_REGEX = /Last updated: \w+, (\d{1,2} \w+ \d{4})/
  ELECTED_SUFFIX_REGEX = /\s*\(\s*\S+\s+elected\s*\)\s*\z/im
  EXCLUDED_CONTEST_REGEX = /\ALeadership Team\b/i
  ELECTED_CANDIDATES_HEADING = 'Elected candidates'.freeze

  def self.call(page)
    new(page).call
  end

  def initialize(page)
    @page = page
  end

  def call
    doc = Nokogiri::HTML(page)

    tables = elected_candidates_tables(doc)
    return nil if tables.empty?

    declared_date = parse_last_updated(doc)
    return nil if declared_date.nil?

    { declared_date:, candidates: tables.flat_map { |table| candidates(table) } }
  end

  private

  attr_reader :page

  def elected_candidates_tables(doc)
    doc.xpath("//h3[normalize-space(text())='#{ELECTED_CANDIDATES_HEADING}']").filter_map do |heading|
      next nil if excluded_contest?(heading)

      heading.xpath('following::table[contains(@class, "multicolumn-results-table")]').first
    end
  end

  # A contest's title is the nearest preceding h2/h3 heading that isn't itself an
  # "Elected candidates" heading -- e.g. "Akoonah Ward (1 vacancy)" or "Leadership
  # Team (election of 1 Lord Mayor and 1 Deputy Lord Mayor)".
  def excluded_contest?(elected_heading)
    title = elected_heading.xpath(
      "preceding::h2 | preceding::h3[normalize-space(text()) != '#{ELECTED_CANDIDATES_HEADING}']"
    ).last&.text.to_s

    title.match?(EXCLUDED_CONTEST_REGEX)
  end

  def parse_last_updated(doc)
    text = doc.text
    match = text.match(LAST_UPDATED_REGEX)
    return nil if match.nil?

    Date.parse(match[1])
  end

  def candidates(table)
    table.css('td.list-item-body').filter_map do |cell|
      name = clean_name(cell.text)
      next nil if name.blank?

      { name:, party: '' }
    end
  end

  def clean_name(raw_text)
    raw_text.strip.sub(ELECTED_SUFFIX_REGEX, '').strip
  end
end
