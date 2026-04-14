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
    find_group_by_external_id || find_sole_group_by_name_and_append_external_id || create_group_with_external_id
  end

  private

  def find_group_by_external_id
    group = ExternalIdentifier.find_by(source:, owner_type: 'Group', value: identifier.to_s)&.owner
    return unless group

    add_to_trading_names(group) if group.name != name

    group
  end

  def find_sole_group_by_name_and_append_external_id
    groups = Group.where(name:)

    if groups.empty?
      nil
    elsif groups.count > 1
      Rails.logger.info("Multiple groups found with name: #{name}")
      NewRelic::Agent.notice_error("Cannot Disambiguate Group name: #{name}")
      nil
    elsif groups.count == 1
      group = groups.first

      existing_id = group.public_send(id_attribute)

      if existing_id.present? && existing_id != identifier
        # there is one group with the name but it has a different external ID.
        return nil
      elsif existing_id.blank?
        # one group exists, but no external ID is set - we can update this group with the external ID

        group.public_send(:"#{id_attribute}=", identifier)
      end

      add_to_trading_names(group)
      group
    end
  end

  def create_group_with_external_id
    group = Group.new(name:)

    save_inside_advisory_lock!(group)
    add_to_trading_names(group)

    group.public_send(:"#{id_attribute}=", identifier)
    group
  end
end
