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
    group = Group.find_by_name_i(name) # rubocop:disable Rails/DynamicFindBy
    return if group.nil?

    existing_id = group.public_send(id_attribute)
    return if existing_id.present? && existing_id != identifier

    if Group.where('LOWER(name) = ?', name.downcase).count > 1
      Rails.logger.info("Multiple groups found with similar name for: #{name}")
      NewRelic::Agent.notice_error("Cannot Disambiguate Group name: #{name}")
      return nil
    end

    add_to_trading_names(group)

    group.public_send(:"#{id_attribute}=", identifier)
    group.save!
    group
  end

  def create_group_with_external_id
    group = Group.new(name:)

    begin
      save_inside_advisory_lock!(group)
    rescue ActiveRecord::RecordInvalid => e
      raise e unless e.message.match?(/Name has already been taken/)

      # Temporary disambiguation until unique name constraint is removed
      group.name = "#{name}|#{source.upcase} ID: #{identifier}"
      group.save!
    end
    add_to_trading_names(group)

    group.public_send(:"#{id_attribute}=", identifier)
    group.save!
    group
  end
end
