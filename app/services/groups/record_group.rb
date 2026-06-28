class Groups::RecordGroup
  attr_reader :name, :business_number, :group, :mapper, :aec_id, :acnc_id

  def initialize(name, business_number: nil, mapper: nil, aec_id: nil, acnc_id: nil)
    @name = mapper.present? ? mapper.call(name) : name
    @business_number = business_number.present? ? business_number&.gsub(/\D/, '') : nil
    @mapper = mapper
    @aec_id = aec_id
    @acnc_id = acnc_id
  end

  def self.call(name, business_number: nil, mapper: nil, aec_id: nil, acnc_id: nil)
    new(name, business_number:, mapper:, aec_id:, acnc_id:).call
  end

  def call
    if business_number.present?
      Groups::Record::RecordGroupWithBusinessNumber.new(name:, business_number:).call
    elsif external_id
      Entity::RecordEntityWithExternalId.new(name:, identifier:, source:, id_attribute:, klass: 'Group').call
    elsif one_group_exists?
        Group.find_sole_by(name:)
    elsif TradingName.where(name:).count > 1
        Rails.logger.info("Multiple trading names found for: #{name}")
        NewRelic::Agent.notice_error("Cannot Disambiguate Trading name: #{name}")

        raise ActiveRecord::ArgumentError, "Attempting to create Group with name: #{name}. Multiple trading names exist with the same name, cannot disambiguate"
    elsif (tn = TradingName.find_by(name:))
        tn.owner
    else
      Groups::Record::RecordGroupWithName.new(name:).call
    end
  end

  private

  attr_reader :source, :identifier, :id_attribute

  def external_id
    # If we have an external identifier, then set all of the relevant instance variables
    return false unless aec_id.present? || acnc_id.present?

    @source, @identifier, @id_attribute = if aec_id.present?
                                            ['aec', aec_id.to_s, 'aec_id']
                                          elsif acnc_id.present?
                                            ['acnc', acnc_id.to_s, 'acnc_id']
                                          end
  end

  def one_group_exists?
    groups = Group.where(name:)
    return false if groups.empty?

    raise ActiveRecord::RecordNotUnique, "Multiple groups exist with the name: #{name}" if groups.many?

    true
  end
end

