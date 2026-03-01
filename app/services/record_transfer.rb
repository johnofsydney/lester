class RecordTransfer
  attr_reader :giver, :taker, :effective_date, :amount, :transfer_type, :evidence

  def initialize(giver, taker, effective_date, amount, transfer_type, evidence)
    @giver = giver
    @taker = taker
    @effective_date = effective_date
    @amount = amount
    @transfer_type = transfer_type
    @evidence = evidence
  end

  def self.call(giver:, taker:, effective_date:, amount: 0, transfer_type:, evidence:)
    new(giver, taker, effective_date, amount, transfer_type, evidence).call
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