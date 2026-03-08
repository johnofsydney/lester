class IndividualTransaction < ApplicationRecord
  belongs_to :transfer
  belongs_to :giver, polymorphic: true
  belongs_to :taker, polymorphic: true
  belongs_to :fine_grained_transaction_category
  has_one :major_transaction_category, through: :fine_grained_transaction_category

  validates :amount, presence: true
  validates :effective_date, presence: true

  scope :government_contracts, -> { where(transfer_type: 'Government Contract') }
  scope :donations, -> { where(transfer_type: 'Australian Political Donations') }
end
