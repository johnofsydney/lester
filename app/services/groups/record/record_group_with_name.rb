class Groups::Record::RecordGroupWithName
  include Record::SavingHelpers

  def initialize(name:)
    @name = name
  end

  attr_reader :name

  def call
    group = Group.new(name:)

    save_inside_advisory_lock!(group)
    add_to_trading_names(group)

    group
  end
end
