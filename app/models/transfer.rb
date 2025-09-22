require 'active_support/all'

class Transfer < ApplicationRecord
  belongs_to :giver, polymorphic: true  # could be a Person or a Group
  belongs_to :taker, polymorphic: true  # could be a Person or a Group

  has_many :individual_transactions, dependent: :destroy

  validates :amount, presence: true
  validates :effective_date, presence: true
  validates :giver_type, uniqueness: {
    scope: [:giver_id, :taker_id, :amount, :effective_date],
    message: 'should have unique combination of giver_type, giver_id, taker_id, amount, and effective_date'
  }

  def self.financial_years
    (Transfer.order(:effective_date).first.effective_date.year..Time.zone.now.year).to_a
  end

  # cached data can be deleted and re-created
  store_accessor :data, %i(giver_name taker_name), prefix: :cached
  # other data is immutable
  store_accessor :data, %i(donations)

  attr_accessor :depth, :direction, :giver_name, :taker_name

  def financial_year
    effective_date.year
  end

  def to_h
    {
      id:,
      amount: amount.round(0),
      effective_date:,
      giver_type: giver.class.to_s,
      giver_id: giver.id,
      giver_name: giver.name,
      taker_type: taker.class.to_s,
      taker_id: taker.id,
      taker_name: taker.name,
      depth:,
      direction:
    }
  end

  def augment(depth:, direction:)
    self.depth = depth
    self.direction = direction
    self.giver_name = giver.name
    self.taker_name = taker.name

    self
  end
end