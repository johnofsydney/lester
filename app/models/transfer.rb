require 'active_support/all'

class Transfer < ApplicationRecord
  belongs_to :giver, polymorphic: true  # could be a Person or a Group
  belongs_to :taker, polymorphic: true  # could be a Person or a Group

  has_many :individual_transactions, dependent: :destroy

  validates :amount, presence: true
  validates :effective_date, presence: true
  validates :giver_type, uniqueness: {
    scope: [:giver_id, :taker_id, :amount, :transfer_type, :effective_date],
    message: 'should have unique combination of giver_type, giver_id, taker_id, amount, transfer_type and effective_date'
  }
  validates :giver_id, :taker_id, presence: true

  scope :government_contracts, -> { where(transfer_type: 'Government Contract(s)') }
  scope :donations, -> { where(transfer_type: 'donations') }

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
  rescue StandardError=> e
    # If there is a giver_id but no giver (or taker), log the error
    NewRelic::Agent.notice_error(e) if defined?(NewRelic)
    Rails.logger.error "Error augmenting Transfer ID #{id}: #{e.message}"
    nil
  end

  def extra_valid?
    return false unless valid?

    giver.present? && taker.present?
  rescue StandardError => e
    Rails.logger.error "Error validating Transfer ID #{id}: #{e.message}"
    false
  end
end