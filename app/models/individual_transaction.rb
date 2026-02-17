class IndividualTransaction < ApplicationRecord
  belongs_to :transfer
  belongs_to :giver, polymorphic: true, optional: true # remove optional later
  belongs_to :taker, polymorphic: true, optional: true # remove optional later
  belongs_to :fine_grained_transaction_category, optional: true # remove optional later
  has_one :major_transaction_category, through: :fine_grained_transaction_category

  validates :amount, presence: true
  validates :effective_date, presence: true
end
