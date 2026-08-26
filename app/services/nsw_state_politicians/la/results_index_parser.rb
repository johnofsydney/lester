# Parses the NSW state election LA results hub page
# (https://pastvtr.elections.nsw.gov.au/SG<event_id>/LA/results) into the electorate slugs used to
# build each electorate's fp_summary URL. Confirmed live: 93 electorates for SG2301, hyphenated
# multi-word slugs (e.g. "badgerys-creek").
class NswStatePoliticians::La::ResultsIndexParser
  FP_SUMMARY_HREF = %r{\A/SG\d+/LA/([a-z0-9-]+)/cc/fp_summary\z}

  def self.call(page) = new(page).call

  def initialize(page)
    @page = page
  end

  def call
    doc = Nokogiri::HTML(page)

    doc.css('a[href]').filter_map { |link| electorate_slug_from(link) }.uniq
  end

  private

  attr_reader :page

  def electorate_slug_from(link)
    match = link['href'].to_s.match(FP_SUMMARY_HREF)
    match && match[1]
  end
end
