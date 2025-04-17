require 'active_support/all'

class Transfer < ApplicationRecord
  belongs_to :giver, polymorphic: true  # could be a Person or a Group
  belongs_to :taker, polymorphic: true  # could be a Person or a Group

  validates :amount, presence: true
  validates :effective_date, presence: true
  validates :giver_type, uniqueness: {
    scope: [:giver_id, :taker_id, :amount, :effective_date],
    message: "should have unique combination of giver_type, giver_id, taker_id, amount, and effective_date"
  }

  def self.financial_years
    (Transfer.order(:effective_date).first.effective_date.year..Time.zone.now.year).to_a
  end

  # cached data can be deleted and re-created
  store_accessor :data, %i(giver_name taker_name), prefix: :cached
  # other data is immutable
  store_accessor :data, %i(donations)

  def financial_year
    effective_date.year
  end

  def giver_name
    if cached_giver_name.blank?
      self.update(cached_giver_name: giver.name)
    end

    cached_giver_name
  end

  def taker_name
    self.update(cached_taker_name: taker.name) if cached_taker_name.blank?

    cached_taker_name
  end
end