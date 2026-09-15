class TradingName < ApplicationRecord
  class AmbiguousName < StandardError; end

  include PgSearch::Model
  multisearchable against: [:name]

  belongs_to :owner, polymorphic: true # could be a Group or a Person

  SOURCES = %w[ingest abn manual].freeze

  validates :owner_type, presence: true
  validates :name, presence: true
  validates :source, inclusion: { in: SOURCES }

  normalizes :name, with: ->(name) { name.downcase.strip.delete('.') }

  def self.sole_owner_for(name, owner_type:)
    matches = where(name:, owner_type:).limit(2).to_a

    if matches.many?
      Rails.logger.info("Multiple trading names found for: #{name}")
      NewRelic::Agent.notice_error("Cannot Disambiguate Trading name: #{name}")

      raise AmbiguousName, "Multiple #{owner_type} trading names exist with the name: #{name}, cannot disambiguate"
    end

    matches.first&.owner
  end
end
