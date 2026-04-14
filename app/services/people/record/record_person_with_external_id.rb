class People::Record::RecordPersonWithExternalId
  include Record::SavingHelpers

  def initialize(name:, identifier:, source:, id_attribute:)
    @name = name
    @identifier = identifier # the value of the external ID (eg aec_id or acnc_id)
    @source = source # eg 'aec' or 'acnc'
    @id_attribute = id_attribute # eg 'aec_id' or 'acnc_id'
  end

  attr_reader :name, :identifier, :source, :id_attribute

  def call
    find_person_by_external_id || find_sole_person_by_name_and_append_external_id || create_person_with_external_id
  end

  private

  def find_person_by_external_id
    person = ExternalIdentifier.find_by(source:, owner_type: 'Person', value: identifier.to_s)&.owner
    return unless person

    add_to_trading_names(person) if person.name != name

    person
  end

  def find_sole_person_by_name_and_append_external_id
    people = Person.where(name:)

    if people.empty?
      nil
    elsif people.count > 1
      Rails.logger.info("Multiple people found with name: #{name}")
      NewRelic::Agent.notice_error("Cannot Disambiguate Person name: #{name}")
      nil
    elsif people.count == 1
      person = people.first

      existing_id = person.public_send(id_attribute)

      if existing_id.present? && existing_id != identifier
        # there is one person with the name but it has a different external ID.
        return nil
      elsif existing_id.blank?
        # one person exists, but no external ID is set - we can update this person with the external ID

        person.public_send(:"#{id_attribute}=", identifier)
      end

      add_to_trading_names(person)
      person
    end
  end

  def create_person_with_external_id
    person = Person.new(name:)

    save_inside_advisory_lock!(person)
    add_to_trading_names(person)

    person.public_send(:"#{id_attribute}=", identifier)
    person
  end
end
