class People::Record::RecordPersonWithName
  include Record::SavingHelpers

  def initialize(name:)
    @name = name
  end

  attr_reader :name

  def call
    person = Person.new(name:)

    person = save_inside_advisory_lock!(person) { Person.find_by(name:) }
    add_to_trading_names(person) if person.previously_new_record?

    person
  end
end
