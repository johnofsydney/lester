# Parses a date from scraped page text, returning nil (rather than raising) on blank input or an
# unparseable format -- election result pages routinely have empty/malformed date cells.
module Councils::SafeDateParse
  def self.call(text, format: nil)
    return nil if text.blank?

    format ? Date.strptime(text, format) : Date.parse(text)
  rescue Date::Error
    nil
  end
end
