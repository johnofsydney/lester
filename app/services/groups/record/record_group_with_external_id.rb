class Groups::Record::RecordGroupWithExternalId
  include Record::SavingHelpers

  def initialize(name:, identifier:, source:, id_attribute:)
    @name = name
    @identifier = identifier # the value of the external ID (eg aec_id or acnc_id)
    @source = source # eg 'aec' or 'acnc'
    @id_attribute = id_attribute # eg 'aec_id' or 'acnc_id'
  end

  attr_reader :name, :identifier, :source, :id_attribute

  def call
    Entity::RecordEntityWithExternalId.new(name:, identifier:, source:, id_attribute:, klass: 'Group').call
  end
end
