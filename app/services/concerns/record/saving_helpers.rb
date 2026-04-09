module Record::SavingHelpers
  extend ActiveSupport::Concern

  def save_inside_advisory_lock!(entity)
    entity.class.transaction do
      lock_id = Zlib.crc32(name).to_i
      entity.class.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")

      entity.save!
    end

    entity
  end

  def add_to_trading_names(entity)
    entity.trading_names.create!(name:) unless entity.trading_names.where(name:).exists?
  end
end
