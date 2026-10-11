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

  scope :duplicating_owner_name, lambda {
    where(
      "(trading_names.owner_type = 'Person' AND EXISTS (SELECT 1 FROM people WHERE people.id = trading_names.owner_id AND people.name = trading_names.name))
       OR (trading_names.owner_type = 'Group' AND EXISTS (SELECT 1 FROM groups WHERE groups.id = trading_names.owner_id AND groups.name = trading_names.name))"
    )
  }

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
