class Position < ApplicationRecord
  include PgSearch::Model
  multisearchable against: [:title]

  belongs_to :membership
end