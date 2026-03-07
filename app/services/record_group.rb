class RecordGroup
  attr_reader :name, :business_number, :group, :mapper, :aec_id

  def initialize(name, business_number = nil, mapper = nil, aec_id = nil)
    @name = mapper.present? ? mapper.call(name) : name
    @business_number = business_number.present? ? business_number&.gsub(/\D/, '') : nil
    @mapper = mapper
    @aec_id = aec_id
  end

  def self.call(name, business_number: nil, mapper: nil, aec_id: nil)
    new(name, business_number, mapper, aec_id).call
  end

  def call
    if business_number.present?
      Group.find_by(business_number:) || find_group_and_append_business_number || create_group_with_business_number
    elsif aec_id.present?
      Group.find_by(aec_id:) || find_group_and_append_aec_id || create_group_with_aec_id
    elsif (group = Group.find_by_name_i(name)) # rubocop:disable Rails/DynamicFindBy
        group
    elsif TradingName.where(name:).count > 1
        Rails.logger.info("Multiple trading names found for: #{name}")
        NewRelic::Agent.notice_error("Cannot Disambiguate Trading name: #{name}")

        nil
    elsif (tn = TradingName.find_by(name:))
        tn.owner
    else
      create_group_with_name
    end
  end

  def find_group_and_append_business_number
    group = Group.find_by_name_i(name) # rubocop:disable Rails/DynamicFindBy
    return if group.nil?

    group.update!(business_number:)
    group
  end

  def create_group_with_business_number
    Group.transaction do
      lock_id = Zlib.crc32(name).to_i
      Group.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")

      group = Group.new(name:, business_number:)
      group.save!
    end

    UpdateGroupNamesFromAbnJob.perform_async(group.id) if group.id.present?

    group
  end

  def find_group_and_append_aec_id
    group = Group.find_by_name_i(name) # rubocop:disable Rails/DynamicFindBy
    return if group.nil?

    group.update!(aec_id:)
    group
  end

  def create_group_with_aec_id
    Group.transaction do
      lock_id = Zlib.crc32(name).to_i
      Group.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")

      group = Group.new(name:, aec_id:)
      group.save!
    end

    group
  end

  def create_group_with_name
    Group.transaction do
      lock_id = Zlib.crc32(name).to_i
      Group.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")

      group = Group.new(name:)
      group.save!
    end

    group
  end
end

