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

# The change to pass a block of Person.find_by(name:) to save_inside_advisory_lock!
# is apparently to avoid a race condition, but it seems also to help if the Person is NOT FOUND in the RecordPerson class

# It was introduced as part of the lobbyists de-duplication work
# https://github.com/johnofsydney/lester/commit/dac98f4dd1f79b02c4597d7fef7cbf2e05eeb856#diff-8bfca1679492ca8199bc699df819427c06a842c948c681a7e63a82ecc9c379cb