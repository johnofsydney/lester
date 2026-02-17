class FineGrainedTransactionCategory < ApplicationRecord
  belongs_to :major_transaction_category
end
