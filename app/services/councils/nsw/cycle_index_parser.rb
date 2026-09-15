# Parses the NSW Electoral Commission's results-site root (https://pastvtr.elections.nsw.gov.au/)
# into the current-structure LG election cycles it links to under "Local Government Election
# Results" -- confirmed live to be exactly the modern `/LG<id>` cycles (2021, 2024, ...), not the
# legacy `LGE<year>/` ones, which sit under a structurally different site (see
# Councils::Nsw::Elections) and are excluded by the leading-slash href pattern below.
class Councils::Nsw::CycleIndexParser
  CYCLE_LINK_HREF = %r{\A/LG(\d+)\z}

  def self.call(page)
    new(page).call
  end

  def initialize(page)
    @page = page
  end

  def call
    heading = Nokogiri::HTML(page).at_xpath("//h2[normalize-space(text())='Local Government Election Results']")
    return [] if heading.nil?

    heading.xpath('following-sibling::p/a[@href]').filter_map { |link| cycle_from(link) }
  end

  private

  attr_reader :page

  def cycle_from(link)
    match = link['href'].to_s.match(CYCLE_LINK_HREF)
    return nil if match.nil?

    { id: match[0].delete_prefix('/'), year: link.text.strip.to_i }
  end
end
