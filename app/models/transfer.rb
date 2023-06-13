class Transfer < ApplicationRecord
  belongs_to :giver, polymorphic: true
  belongs_to :taker, class_name: 'Group'
end