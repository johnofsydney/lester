require 'active_support/all'

class Transfer < ApplicationRecord
  belongs_to :giver, polymorphic: true  # could be a Person or a Group
  belongs_to :taker, polymorphic: true  # could be a Person or a Group

  validates :amount, presence: true
  validates :effective_date, presence: true
  validates :giver_id, presence: true
  validates :taker_id, presence: true
  validates :giver_type, uniqueness: {
    scope: [:giver_id, :taker_id, :amount, :effective_date],
    message: "should have unique combination of giver_type, giver_id, taker_id, amount, and effective_date"
  }

  def self.financial_years
    [
      2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025,
    ]
  end

  store_accessor :data, %i(donations giver_name taker_name), prefix: :cached

  def financial_year
    effective_date.year
  end

  def giver_name
    unless cached_giver_name.present?
      self.update(cached_giver_name: giver.name)
    end

    cached_giver_name
  end

  def taker_name
    self.update(cached_taker_name: taker.name) unless cached_taker_name.present?

    cached_taker_name
  end
end