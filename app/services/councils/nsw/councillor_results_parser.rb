# Parses a NSW Electoral Commission councillor results page
# (https://pastvtr.elections.nsw.gov.au/LG<election_id>/<slug>/councillor) into the
# declared-elected candidates and the date they were declared, or nil when the
# election for this council hasn't been declared yet.
class Councils::Nsw::CouncillorResultsParser
  DECLARED_DATE_REGEX = /declared elected on (\d{1,2} \w+ \d{4})/

  def self.call(page)
    new(page).call
  end

  def initialize(page)
    @page = page
  end

  def call
    block = Nokogiri::HTML(page).at_css('div.declared-elected')
    return nil if block.nil?

    declared_date = parse_declared_date(block)
    return nil if declared_date.nil?

    { declared_date:, candidates: candidates(block) }
  end

  private

  attr_reader :page

  def parse_declared_date(block)
    text = block.at_css('span.declared-date')&.text.to_s
    match = text.match(DECLARED_DATE_REGEX)
    return nil if match.nil?

    Date.parse(match[1])
  end

  def candidates(block)
    block.css('span.candidate-name').map do |name_span|
      party_span = name_span.next_element
      {
        name: name_span.text.strip,
        party: party_span&.[]('title').to_s.strip
      }
    end
  end
end
