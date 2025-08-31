class IndividualTransaction < ApplicationRecord
  belongs_to :transfer

  validates :amount, presence: true
  validates :effective_date, presence: true
end
