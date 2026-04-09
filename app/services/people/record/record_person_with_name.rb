class People::Record::RecordPersonWithName
  include Record::SavingHelpers

  def initialize(name:)
    @name = name
  end

  attr_reader :name

  def call
    person = Person.new(name:)

    save_inside_advisory_lock!(person)
    add_to_trading_names(person)

    person
  end
end
