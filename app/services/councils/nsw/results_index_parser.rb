# Parses the NSW Electoral Commission's index of local government areas
# (https://pastvtr.elections.nsw.gov.au/LG<election_id>/index) into a list of
# councils and the slug used to build their per-council results URLs.
class Councils::Nsw::ResultsIndexParser
  COUNCIL_LINK_HREF = %r{\A/LG\d+/([a-z0-9-]+)/results\z}

  def self.call(page)
    new(page).call
  end

  def initialize(page)
    @page = page
  end

  def call
    doc = Nokogiri::HTML(page)

    doc.css('div.council-area a[href]').filter_map { |link| council_from(link) }
  end

  private

  attr_reader :page

  def council_from(link)
    match = link['href'].to_s.match(COUNCIL_LINK_HREF)
    return nil if match.nil?

    { name: council_name(link), slug: match[1] }
  end

  def council_name(link)
    # title attribute reads "Election results for <Full Council Name>"
    title = link['title'].to_s.delete_prefix('Election results for ').strip

    title.presence || link.text.strip
  end
end
