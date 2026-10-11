# Parses a NSW Electoral Commission by-election Distribution of Preferences report page
# (https://results.elections.nsw.gov.au/LB<id>/<council>/.../DistributionOfPreferencesReport.html)
# into the elected candidate and the report's own "last updated" date, or nil if not yet declared.
#
# Structurally unrelated to Councils::Nsw::CouncillorResultsParser's `div.declared-elected` block
# -- a by-election's result lives on a completely different site (results.elections.nsw.gov.au,
# not pastvtr) rendering raw per-venue vote-count tables, not a pre-summarised declared-winner
# block. The elected candidate's row carries `class="Elected"` (confirmed live at
# LB2401/Berrigan/Councillor/DistributionOfPreferencesReport.html).
class Councils::Nsw::ByElectionResultsParser
  LAST_UPDATED_REGEX = %r{Report was last updated on\s*-\s*(\d{1,2}/\d{1,2}/\d{4})}

  def self.call(page)
    new(page).call
  end

  def initialize(page)
    @page = page
  end

  def call
    doc = Nokogiri::HTML(page)

    elected_name = doc.at_css('tr.Elected td')&.text&.strip
    declared_date = parse_declared_date(doc)
    return nil if elected_name.blank? || declared_date.nil?

    { declared_date:, candidates: [{ name: reorder_name(elected_name), party: '' }] }
  end

  private

  attr_reader :page

  # This report renders names as "SURNAME Given" with no comma (confirmed live), unlike the
  # general-cycle pages' "Given Surname" order -- so People::RecordPerson.clean_name's own
  # comma-triggered reversal never fires here. Reverse it ourselves: the surname is the leading
  # run of all-uppercase words.
  def reorder_name(name)
    words = name.split
    surname_words = words.take_while { |word| word == word.upcase }
    return name if surname_words.empty? || surname_words.size == words.size

    (words[surname_words.size..] + surname_words).join(' ')
  end

  def parse_declared_date(doc)
    match = doc.at_css('h4')&.text&.match(LAST_UPDATED_REGEX)
    return nil if match.nil?

    Councils::SafeDateParse.call(match[1], format: '%d/%m/%Y')
  end
end
