class Membership < ApplicationRecord
  belongs_to :person
  belongs_to :group
end