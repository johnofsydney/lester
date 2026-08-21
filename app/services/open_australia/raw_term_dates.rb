module OpenAustralia::RawTermDates
  def contiguous?(prev, curr)
    prev['left_house'] == curr['entered_house']
  end

  def parse_date(date_string)
    return nil if date_string.blank? || date_string == '9999-12-31'

    Date.parse(date_string)
  rescue Date::Error
    nil
  end
end
