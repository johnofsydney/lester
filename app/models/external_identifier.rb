class ExternalIdentifier < ApplicationRecord
  belongs_to :owner, polymorphic: true # Person or Group

  validates :owner_id, :owner_type, presence: true
  validates :source, presence: true
  validates :value, presence: true
  validates :value, uniqueness: { scope: %i[owner_type owner_id source] }

  SOURCES = %w[aec acnc open_politics].freeze
end
