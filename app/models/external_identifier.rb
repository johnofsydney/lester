class ExternalIdentifier < ApplicationRecord
  belongs_to :owner, polymorphic: true  # Person or Group

  validates :owner_id, :owner_type, presence: true
  validates :source, presence: true
  validates :value, presence: true
  validates :source, uniqueness: { scope: :value, message: 'and value combination already exists' }
  validates :source, uniqueness: { scope: [:owner_type, :owner_id], message: 'already exists for this owner' }

  SOURCES = %w[aec acnc open_politics].freeze
end
