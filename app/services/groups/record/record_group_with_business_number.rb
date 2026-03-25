class Groups::Record::RecordGroupWithBusinessNumber
  include Record::SavingHelpers

  def initialize(name:, business_number:)
    @name = name
    @business_number = business_number
  end

  attr_reader :name, :business_number

  def call
    Group.find_by(business_number:) || find_group_and_append_business_number || create_group_with_business_number
  end

  def find_group_and_append_business_number
    group = Group.find_by_name_i(name) # rubocop:disable Rails/DynamicFindBy
    return if group.nil?

    group.update!(business_number:)
    group
  end

  def create_group_with_business_number
    group = Group.new(name:, business_number:)

    save_inside_advisory_lock!(group)

    UpdateGroupNamesFromAbnJob.perform_async(group.id) if group.id.present?

    group
  end
end
