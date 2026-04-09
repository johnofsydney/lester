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
    person = Person.find_by_name_i(name) # rubocop:disable Rails/DynamicFindBy
    return unless person

    existing_id = person.public_send(id_attribute)
    return if existing_id.present? && existing_id != identifier

    if Person.where('LOWER(name) = ?', name.downcase).count > 1
      Rails.logger.info("Multiple people found with similar name for: #{name}")
      NewRelic::Agent.notice_error("Cannot Disambiguate Person name: #{name}")
      return nil
    end

    person.public_send(:"#{id_attribute}=", identifier)
    person.save!
    person
  end

  def create_person_with_external_id
    person = Person.new(name:)

    begin
      save_inside_advisory_lock!(person)
      person.save!
    rescue ActiveRecord::RecordInvalid => e
      raise e unless e.message.match?(/Name has already been taken/)

      # Temporary disambiguation until unique name constraint is removed
      person.name = "#{name}||#{source.upcase} ID: #{identifier}"
      person.save!
    end
    add_to_trading_names(person)

    person.public_send(:"#{id_attribute}=", identifier)
    person.save!
    person
  end
end
