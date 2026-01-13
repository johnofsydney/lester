class RecordGroup
  attr_reader :name, :business_number, :group, :mapper

  def initialize(name, business_number = nil, mapper = nil)
    @name = mapper.present? ? mapper.call(name) : name
    @business_number = business_number.present? ? business_number&.gsub(/\D/, '') : nil
    @mapper = mapper
  end

  def self.call(name, business_number: nil, mapper: nil)
    new(name, business_number, mapper).call
  end

  def call
    if business_number.present?
      Group.find_by(business_number:) || find_group_and_append_business_number || create_group_with_business_number
    elsif (group = find_group_by_name)
        group
    elsif TradingName.where(name:).count > 1
        raise "Cannot Disambiguate Trading name: #{name}"
    elsif (tn = TradingName.find_by(name:))
        tn.owner
    else
      create_group_with_name
    end
  end

  def find_group_and_append_business_number
    group = find_group_by_name
    return if group.nil?

    group.update!(business_number:)
    group
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

  def find_group_by_name
    Group.where('LOWER(name) = ?', name.downcase).first
  end
end

