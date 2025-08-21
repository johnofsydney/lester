class Dates::FinancialYear
  def initialize(date)
    @date = date.is_a?(String) ? Date.parse(date) : date

  end

  def last_day
    Date.new(year, 6, 30)
  end

  def first_day
    Date.new(year - 1, 7, 1)
  end

  def year = @date.month < 7 ? @date.year : @date.year + 1
end