class Donation < ApplicationRecord
  belongs_to :donor, polymorphic: true
  belongs_to :donee, polymorphic: true
end
