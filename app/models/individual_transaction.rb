class IndividualTransaction < ApplicationRecord
  #   belongs_to :giver, polymorphic: true  # could be a Person or a Group
  # belongs_to :taker, polymorphic: true  # could be a Person or a Group

  validates :amount, presence: true
  validates :effective_date, presence: true

end
