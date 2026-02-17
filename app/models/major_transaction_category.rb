class MajorTransactionCategory < ApplicationRecord
  has_many :fine_grained_transaction_categories
  has_many :individual_transactions, through: :fine_grained_transaction_categories
end
