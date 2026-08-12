class Groups::Record::RecordGroupWithName
  include Record::SavingHelpers

  def initialize(name:)
    @name = name
  end

  attr_reader :name

  def call
    group = Group.new(name:)

    group = save_inside_advisory_lock!(group) { Group.find_by(name:) }
    add_to_trading_names(group) if group.previously_new_record?

    group
  end
end
