module ExternalIdentifiable
  extend ActiveSupport::Concern

  included do
    has_many :external_identifers, as: :owner, dependent: :destroy
  end

  def aec_id
    external_identifer_value('aec')
  end

  def aec_id=(value)
    set_external_identifer('aec', value)
  end

  def acnc_id
    external_identifer_value('acnc')
  end

  def acnc_id=(value)
    set_external_identifer('acnc', value)
  end

  private

  def external_identifer_value(source)
    external_identifers.find_by(source:)&.value
  end

  def set_external_identifer(source, value)
    return if value.blank?

    record = external_identifers.find_or_initialize_by(source:)
    record.value = value
    record.save!
  end
end
