# Parses the Victorian Electoral Commission's by-election/countback timeline
# (https://www.vec.vic.gov.au/results/council-election-results/council-by-elections-and-countbacks-timeline)
# into every by-election and countback event since ~2010, across all its year accordions. Each
# accordion heading (e.g. "2022") is a sibling of that year's table; each row gives a day+month
# date (combined with the accordion's year), a `Type` of "By-election" or "Countback" (used
# directly, not inferred from the slug -- more reliable), and a link to the event's own result
# page (relative to the timeline path, since a plain href attribute is only the trailing slug).
class Councils::Vic::ByElectionIndexParser
  TIMELINE_URL = 'https://www.vec.vic.gov.au/results/council-election-results/council-by-elections-and-countbacks-timeline'.freeze
  KIND_BY_TYPE = {
    'by-election' => :by_election,
    'countback' => :countback
  }.freeze

  def self.call(page)
    new(page).call
  end

  def initialize(page)
    @page = page
  end

  def call
    doc = Nokogiri::HTML(page)

    doc.css('a.accordion-item').flat_map { |heading| events_for_year(heading) }
  end

  private

  attr_reader :page

  def events_for_year(heading)
    year = heading.text.strip.to_i
    content = heading.at_xpath('following-sibling::div[1]')
    return [] if content.nil?

    content.css('tbody tr').filter_map { |row| event_from(row, year) }
  end

  def event_from(row, year)
    cells = row.css('td')
    return nil if cells.size < 3

    kind = KIND_BY_TYPE[cells[1].text.strip.downcase]
    return nil if kind.nil?

    link = cells[2].at_css('a[href]')
    return nil if link.nil?

    {
      kind:,
      council_description: link.text.strip,
      slug: link['href'].to_s.split('/').last,
      date: parse_date(cells[0].text.strip, year)
    }
  end

  def parse_date(day_month, year)
    Councils::SafeDateParse.call("#{day_month} #{year}")
  end
end
