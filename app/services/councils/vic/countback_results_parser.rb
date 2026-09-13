# Parses a Victorian Electoral Commission council countback result page (e.g.
# .../council-by-elections-and-countbacks-timeline/12dec-moira-shire-countback) into the elected
# candidate's name and the countback date. Structurally unrelated to
# Councils::Vic::CouncillorResultsParser's "Elected candidates" table -- a countback recounts
# already-cast ballots to fill a casual vacancy (no fresh vote), and VEC renders it as a plain
# key-value table instead: Vacancy date / Countback date / Vacated / Elected.
class Councils::Vic::CountbackResultsParser
  def self.call(page)
    new(page).call
  end

  def initialize(page)
    @page = page
  end

  def call
    row_text = row_text_by_label(Nokogiri::HTML(page))

    elected_name = row_text['Elected']
    countback_date = parse_date(row_text['Countback date'])
    return nil if elected_name.blank? || countback_date.nil?

    { declared_date: countback_date, candidates: [{ name: elected_name, party: '' }] }
  end

  private

  attr_reader :page

  def row_text_by_label(doc)
    doc.css('table tr').filter_map { |row| label_value(row) }.to_h
  end

  def label_value(row)
    label = row.at_css('th')&.text&.strip
    value = row.at_css('td')&.text&.strip
    return nil if label.blank? || value.blank?

    [label, value]
  end

  def parse_date(text)
    return nil if text.blank?

    Date.parse(text)
  rescue Date::Error
    nil
  end
end
