module Record::SavingHelpers
  extend ActiveSupport::Concern

  def save_inside_advisory_lock!(entity)
    entity.class.transaction do
      lock_id = Zlib.crc32(name).to_i
      entity.class.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")

      existing = yield if block_given?
      next existing if existing

      entity.save!
      entity
    end
  end

  # A trading name identical to the entity's own (normalised) name adds no search or
  # disambiguation value -- Person/Group are already `multisearchable against: [:name]` -- and
  # just duplicates every search hit. Skipped here, centrally, rather than trusting each caller to
  # check first.
  def add_to_trading_names(entity)
    return if normalize_name(name) == entity.name

    entity.trading_names.create!(name:) unless entity.trading_names.where(name:).exists?
  end

  private

  def normalize_name(value)
    value.to_s.downcase.strip.delete('.')
  end
end
