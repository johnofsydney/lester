# Parses a Victorian Electoral Commission council results page
# (https://www.vec.vic.gov.au/results/council-election-results/<year>-council-election-results/<slug>)
# into the elected candidates and the date the page was last updated, or nil when
# there's no "Elected candidates" section yet (results not finalised).
#
# Unlike NSW, VEC results pages don't show party/group affiliation, so only names
# are captured here.
class Councils::Vic::CouncillorResultsParser
  LAST_UPDATED_REGEX = /Last updated: \w+, (\d{1,2} \w+ \d{4})/
  ELECTED_SUFFIX_REGEX = /\s*\(\s*\S+\s+elected\s*\)\s*\z/im

  def self.call(page)
    new(page).call
  end

  def initialize(page)
    @page = page
  end

  def call
    doc = Nokogiri::HTML(page)

    table = elected_candidates_table(doc)
    return nil if table.nil?

    declared_date = parse_last_updated(doc)
    return nil if declared_date.nil?

    { declared_date:, candidates: candidates(table) }
  end

  private

  attr_reader :page

  def elected_candidates_table(doc)
    doc.at_xpath("//h3[contains(text(), 'Elected candidates')]/following::table[contains(@class, 'multicolumn-results-table')][1]")
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
