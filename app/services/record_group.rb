class RecordGroup
  attr_reader :name, :business_number, :group, :mapper

  def initialize(name, business_number = nil, mapper = nil)
    @name = mapper ? mapper.call(name) : name
    @business_number = business_number&.gsub(/\D/, '')
    @mapper = mapper
  end

  def self.call(name, business_number: nil, mapper: nil)
    new(name, business_number, mapper).call
  end

  def call
    if business_number.present?
      Group.find_by(business_number:) || create_group_with_business_number
    elsif (group = Group.find_by(name:))
        group
    elsif (TradingName.where(name:).count > 1)
        raise "Cannot Disambiguate Trading name: #{name}"
    elsif (tn = TradingName.find_by(name:))
        tn.owner
    else
      create_group_with_name
    end
  end

  def create_group_with_business_number
    group = Group.new(name:, business_number:)

    Group.transaction do
      lock_id = Zlib.crc32(group.name).to_i
      Group.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")

      group.save!
    end

    UpdateGroupNamesFromAbnJob.perform_async(group.id)

    group
  end

  def create_group_with_name
    group = Group.new(name:)

    Group.transaction do
      lock_id = Zlib.crc32(group.name).to_i
      Group.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")

      group.save!
    end

    group
  end
end

# to MERGE an entity into another:
# 1. Move all the memberships across
# 1. Move all the other_names across
# 2. Move all the transfers across
# 3. If there are any duplicated transfers (same giver, taker, amount, date) ## NEW ##
#   a. Move any individual transactions across
#   b. Delete the duplicated transfer (the one with no individual transactions)
#   c. Re-calculate the amount on the remaining transfer
# 4. Delete the merged entity
