class People::Record::RecordPersonWithName
  include Record::SavingHelpers

  def initialize(name:)
    @name = name
  end

  attr_reader :name

  def call
    person = Person.new(name:)

    person = save_inside_advisory_lock!(person) { Person.find_by(name:) }
    # TODO: Name Disambiguation: finding the first person by name is fragile
    # TODO:  Name Disambiguation: adding every name to trading names is also fragile
    add_to_trading_names(person) if person.previously_new_record?

    person
  end
end
