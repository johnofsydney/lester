module ExternalIdentifiable
  extend ActiveSupport::Concern

  included do
    has_many :external_identifiers, as: :owner, dependent: :destroy
  end

  def aec_id
    external_identifier_value('aec')
  end

  def aec_id=(value)
    set_external_identifier('aec', value)
  end

  def acnc_id
    external_identifier_value('acnc')
  end

  def acnc_id=(value)
    set_external_identifier('acnc', value)
  end

  private

  def external_identifier_value(source)
    external_identifiers.find_by(source:)&.value
  end

  def set_external_identifier(source, value)
    return if value.blank?

    record = external_identifiers.find_or_initialize_by(source:)
    record.value = value
    record.save!
  end
end
