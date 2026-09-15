# Parses the NSW Electoral Commission's local-election-results archive page
# (https://www.elections.nsw.gov.au/elections/past-results/local-election-results) into every
# by-election/countback event that links to a modern results.elections.nsw.gov.au report -- the
# page embeds every general cycle AND every by-election/countback since 2014 as repeated
# `<h3>heading</h3><p>...</p>...<ul>...</ul>` blocks, with no distinct markup between the two
# kinds, so general-cycle headings (matching GENERAL_CYCLE_REGEX) are excluded here in favour of
# Councils::Nsw::Elections' own dedicated pastvtr-root discovery.
#
# A handful of the oldest events (2014) only link PDF reports with no results.elections.nsw.gov.au
# host at all -- skipped here, same "nothing for this pipeline to record" treatment as
# Councils::Nsw::ResultsPageParser's no-contest councils. council_description is heading free text
# with the date/kind/ward suffix stripped as best effort; NSWEC's own wording is inconsistent
# across two decades of entries, so this is expected to need iteration against live data, not a
# guaranteed match to every council's canonical Group name.
class Councils::Nsw::ByElectionIndexParser
  GENERAL_CYCLE_REGEX = /NSW Local Government elections/i
  DOP_HREF_REGEX = %r{\Ahttps://results\.elections\.nsw\.gov\.au/(LB\d+)/.+/DistributionOfPreferencesReport\.html\z}i
  LEADING_DATE_REGEX = /\A\d{1,2}\s+\w+\s+\d{4}\s*[-–]?\s*/
  DESCRIPTION_CUT_REGEX = / countback| by-election| by election| election|\s+-\s+|\(|\|/i

  def self.call(page)
    new(page).call
  end

  def initialize(page)
    @page = page
  end

  def call
    Nokogiri::HTML(page).css('.general-content h3').filter_map { |heading| event_from(heading) }
  end

  private

  attr_reader :page

  def event_from(heading)
    heading_text = heading.text.strip
    return nil if heading_text.match?(GENERAL_CYCLE_REGEX)

    link = dop_link(heading)
    return nil if link.nil?

    { lb_id: link[1], report_url: link[0], council_description: description(heading_text) }
  end

  def dop_link(heading)
    heading.xpath('following-sibling::ul[1]').first
           &.css('a[href]')
           &.filter_map { |a| a['href'].to_s.match(DOP_HREF_REGEX) }
           &.first
  end

  def description(heading_text)
    without_date = heading_text.sub(LEADING_DATE_REGEX, '')
    without_date.split(DESCRIPTION_CUT_REGEX).first.strip
  end
end
