class Group < ApplicationRecord
  has_many :memberships
  has_many :people, through: :memberships

  has_many :donations, as: :donor
  has_many :donations, as: :donee
end
