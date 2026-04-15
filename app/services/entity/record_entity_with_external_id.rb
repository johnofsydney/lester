class Entity::RecordEntityWithExternalId
  include Record::SavingHelpers

  def initialize(name:, identifier:, source:, id_attribute:, klass:)
    @name = name
    @identifier = identifier # the value of the external ID (eg aec_id or acnc_id)
    @source = source # eg 'aec' or 'acnc'
    @id_attribute = id_attribute # eg 'aec_id' or 'acnc_id'
    @klass = klass.capitalize # eg Group or Person
  end

  attr_reader :name, :identifier, :source, :id_attribute, :klass

  def call
    find_entity_by_external_id || find_sole_entity_by_name_and_append_external_id || create_entity_with_external_id
  end

  private

  def find_entity_by_external_id
    entity = ExternalIdentifier.find_by(source:, owner_type: klass, value: identifier.to_s)&.owner
    return unless entity

    add_to_trading_names(entity) if entity.name != name

    entity
  end

  def find_sole_entity_by_name_and_append_external_id
    entities = klass.constantize.where(name:)
    return if entities.empty? || entities.many?

    entity = entities.first
    existing_id = entity.public_send(id_attribute)
    return if existing_id.present? && existing_id != identifier

    entity.public_send(:"#{id_attribute}=", identifier)
    add_to_trading_names(entity)
    entity
  end

  def create_entity_with_external_id
    entity = klass.constantize.new(name:)

    save_inside_advisory_lock!(entity)
    add_to_trading_names(entity)

    entity.public_send(:"#{id_attribute}=", identifier)
    entity
  end
end
