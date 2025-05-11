class Position < ApplicationRecord
  include PgSearch::Model

  belongs_to :membership

  def formatted_start_date
    start_date.strftime('%d/%m/%Y') if start_date
  end

  def formatted_end_date
    end_date.strftime('%d/%m/%Y') if end_date
  end

  def formatted_start_month_year
    start_date.strftime('%B %Y') if start_date
  end

  def formatted_end_month_year
    end_date.strftime('%B %Y') if end_date
  end
end