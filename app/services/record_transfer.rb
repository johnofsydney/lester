class RecordTransfer
  attr_reader :giver, :taker, :effective_date, :amount, :transfer_type, :evidence

  def initialize(attrs)
    @giver = attrs[:giver]
    @taker = attrs[:taker]
    @effective_date = attrs[:effective_date]
    @amount = attrs[:amount] || 0
    @transfer_type = attrs[:transfer_type]
    @evidence = attrs[:evidence]
  end

  def self.call(attrs)
    new(attrs).call
  end

  def call
    Transfer.transaction do
      lock_id = Zlib.crc32(lock_string).to_i
      Transfer.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")

      Transfer.find_or_create_by!(giver:, taker:, effective_date:, transfer_type:, evidence:)
    end
  end

  def lock_string
    "#{giver.name}-#{taker.name}-#{effective_date}"
  end
end