class FineGrainedTransactionCategory < ApplicationRecord
  belongs_to :major_transaction_category, optional: true

  has_many :individual_transactions, dependent: :nullify
end
