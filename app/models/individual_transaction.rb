class IndividualTransaction < ApplicationRecord
  belongs_to :transfer
  belongs_to :giver, polymorphic: true
  belongs_to :taker, polymorphic: true
  belongs_to :fine_grained_transaction_category
  has_one :major_transaction_category, through: :fine_grained_transaction_category

  validates :amount, presence: true
  validates :effective_date, presence: true

  enum :transaction_type, {
    government_contract: 'government_contract',
    donation: 'donation'
  }

  scope :government_contracts, -> { where(transaction_type: 'government_contract') }
  scope :donations, -> { where(transaction_type: 'donation') }
end
