# Parses the Victorian Electoral Commission's council election results index
# (https://www.vec.vic.gov.au/results/council-election-results) into the general (all-councils)
# cycles it links to. The `<year>-council-election-results` slug is specific to a full general
# cycle -- single-council special elections (e.g. "2021-election-results" for South Gippsland,
# "2017-election-results" for Greater Geelong) use a different slug shape entirely and are
# excluded by the regex below, matching this pipeline's existing scope (see
# Councils::Vic::ResultsIndexParser, which only ever crawls the general-cycle slug shape).
class Councils::Vic::CycleIndexParser
  CYCLE_LINK_HREF = %r{\A/results/council-election-results/(\d{4})-council-election-results\z}

  def self.call(page)
    new(page).call
  end

  def initialize(page)
    @page = page
  end

  def call
    Nokogiri::HTML(page).css('a[href]').filter_map { |link| cycle_from(link) }.uniq { |cycle| cycle[:year] }
  end

  private

  attr_reader :page

  def cycle_from(link)
    match = link['href'].to_s.match(CYCLE_LINK_HREF)
    return nil if match.nil?

    { year: match[1].to_i }
  end
end
