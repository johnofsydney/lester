# Parses the Victorian Electoral Commission's index of council election results
# (https://www.vec.vic.gov.au/results/council-election-results/<year>-council-election-results)
# into a list of councils and the slug used to build their per-council results URLs.
class Councils::Vic::ResultsIndexParser
  COUNCIL_LINK_HREF = %r{\A/results/council-election-results/\d{4}-council-election-results/([a-z0-9-]+)\z}

  def self.call(page)
    new(page).call
  end

  def initialize(page)
    @page = page
  end

  def call
    doc = Nokogiri::HTML(page)

    doc.css('a[href]').filter_map { |link| council_from(link) }.uniq { |council| council[:slug] }
  end

  private

  attr_reader :page

  def council_from(link)
    match = link['href'].to_s.match(COUNCIL_LINK_HREF)
    return nil if match.nil?

    { name: link.text.strip, slug: match[1] }
  end
end
