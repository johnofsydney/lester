class FineGrainedTransactionCategory < ApplicationRecord
  belongs_to :major_transaction_category

  has_many :individual_transactions, dependent: :nullify
end
