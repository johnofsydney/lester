require 'rails_helper'

RSpec.describe ExternalIdentifier do
  describe 'validations' do
    it 'validates uniqueness of value scoped to owner_type, owner_id, and source' do
      uniqueness_validator = described_class.validators_on(:value)
                                           .find { |validator| validator.is_a?(ActiveRecord::Validations::UniquenessValidator) }

      expect(uniqueness_validator).to be_present
      expect(uniqueness_validator.options[:scope]).to eq(%i[owner_type owner_id source])
    end

    it 'does not allow duplicate owner_type, owner_id, source, value combinations' do
      owner = Group.create!(name: 'External Identifier Owner Group')
      described_class.create!(owner:, source: 'aec', value: 'AEC-123')

      duplicate = described_class.new(owner:, source: 'aec', value: 'AEC-123')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:value]).to include('has already been taken')
    end
  end
end
