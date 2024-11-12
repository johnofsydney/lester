class Position < ApplicationRecord
  include PgSearch::Model

  belongs_to :membership

  def formatted_start_date
    start_date.strftime("%d/%m/%y") if start_date
  end

  def formatted_end_date
    end_date.strftime("%d/%m/%y") if end_date
  end
end