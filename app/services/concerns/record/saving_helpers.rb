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
    return if TradingName.normalize_value_for(:name, name) == entity.name

    entity.trading_names.create_or_find_by!(name:)
  end
end
