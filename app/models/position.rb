class Position < ApplicationRecord
  include PgSearch::Model

  belongs_to :membership

  def formatted_start_date
    return unless start_date

    formatting = formatting_for_date(start_date)

    start_date.strftime(formatting)
  end

  def formatted_end_date
    return unless end_date

    formatting = formatting_for_date(end_date)

    end_date.strftime(formatting)
  end

  def formatted_start_month_year
    start_date.strftime('%B %Y') if start_date
  end

  def formatted_end_month_year
    end_date.strftime('%B %Y') if end_date
  end

  def formatting_for_date(date)
    days_in_month = Time.days_in_month(date.month, date.year)

    case
    when [1, days_in_month].include?(date.day)
      '%B %Y'
    else
      '%d/%m/%Y'
    end
  end
end