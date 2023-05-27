class Membership < ApplicationRecord
  belongs_to :member, polymorphic: true
  belongs_to :owner, class_name: 'Group'
end