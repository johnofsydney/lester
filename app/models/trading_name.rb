class TradingName < ApplicationRecord
  include PgSearch::Model
  multisearchable against: [:name]

  belongs_to :owner, polymorphic: true # could be a Group or a Person

  validates :owner_id, :owner_type, presence: true
  validates :name, presence: true
end
