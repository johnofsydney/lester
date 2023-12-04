require 'active_support/all'

class Transfer < ApplicationRecord
  belongs_to :giver, polymorphic: true
  belongs_to :taker, class_name: 'Group'

  def formatted_amount
    "$#{amount}"
  end
end