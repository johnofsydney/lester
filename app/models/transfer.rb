require 'active_support/all'

class Transfer < ApplicationRecord
  belongs_to :giver, polymorphic: true  # could be a Person or a Group
  belongs_to :taker, class_name: 'Group'

  validates :amount, presence: true
  validates :effective_date, presence: true
  validates :giver, presence: true
  validates :taker, presence: true
  validates :giver_type, uniqueness: {
    scope: [:giver_id, :taker_id, :amount, :effective_date],
    message: "should have unique combination of giver_type, giver_id, taker_id, amount, and effective_date"
  }

  def formatted_amount
    "$#{amount}"
  end
end