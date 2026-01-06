class RecordGroup
  attr_reader :name, :category, :business_number, :group, :mapper

  def initialize(name, category = nil, business_number = nil, mapper = nil)
    @name = mapper ? mapper.call(name) : name
    @category = !category.nil?
    @business_number = business_number&.gsub(/\D/, '')
    @mapper = mapper
  end

  def self.call(name, category: nil, business_number: nil, mapper: nil)
    new(name, category, business_number, mapper).call
  end

  def call
    if business_number.present? && (@group = Group.find_by(business_number:))
      @group.other_names << name if add_new_name_to_other_names?
    elsif (@group = Group.find_by(name:))
      @group.business_number = business_number if business_number.present?
    else
      @group = business_number.present? ? Group.create(name:, business_number:) : Group.create(name:)
    end

    Group.transaction do
      lock_id = Zlib.crc32(@group.name).to_i
      Group.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")

      @group.update(category:) if category
      @group.save
    end

    @group
  end

  def add_new_name_to_other_names?
    name != @group.name && @group.other_names.exclude?(name)
  end
end
