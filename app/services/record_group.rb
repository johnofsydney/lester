class RecordGroup
  attr_reader :name, :category, :business_number, :group

  def initialize(name, category = nil, business_number = nil)
    @name = MapGroupNames.new(name).call
    @category = !category.nil?
    @business_number = business_number&.gsub(/\D/, '')
  end

  def self.call(name, category: nil, business_number: nil)
    new(name, category, business_number).call
  end

  def call
    if business_number.present? && (@group = Group.find_by(business_number:))
      @group.other_names << name if add_new_name_to_other_names?
    elsif (@group = Group.find_by(name:))
      @group.business_number = business_number if business_number.present?
    else
      @group = Group.create(name:, business_number:)
    end

    @group.update(category:) if category
    @group.save

    @group
  end

  def add_new_name_to_other_names?
    name != @group.name && @group.other_names.exclude?(name)
  end
end
