require 'rails_helper'

RSpec.describe Councils::RecordCandidatePerson, type: :service do
  let(:council) { FactoryBot.create(:group, name: 'Federation Council') }
  let(:other_council) { FactoryBot.create(:group, name: 'Albury City Council') }

  describe '#call' do
    context 'when no Person with this name exists at all' do
      it 'creates a new Person' do
        expect do
          described_class.call(name: 'John Smith', council:)
        end.to change(Person, :count).by(1)
      end
    end

    context 'when a Person with this name already has a Membership at this council' do
      let!(:existing_person) { FactoryBot.create(:person, name: 'John Smith') }

      before { Membership.create!(group: council, member: existing_person) }

      it 'reuses that Person rather than creating a new one' do
        expect do
          expect(described_class.call(name: 'John Smith', council:)).to eq(existing_person)
        end.not_to change(Person, :count)
      end
    end

    context 'when a Person with this name exists, but only at a different council' do
      let!(:other_councils_person) { FactoryBot.create(:person, name: 'John Smith') }

      before { Membership.create!(group: other_council, member: other_councils_person) }

      it 'creates a new, separate Person rather than reusing the unrelated one' do
        result = nil

        expect do
          result = described_class.call(name: 'John Smith', council:)
        end.to change(Person, :count).by(1)

        expect(result).not_to eq(other_councils_person)
      end
    end

    context 'when a Person with this name exists but has no council Membership at all (e.g. from AEC donation data)' do
      let!(:unrelated_person) { FactoryBot.create(:person, name: 'John Smith') }

      it 'creates a new, separate Person rather than reusing the unrelated one' do
        result = nil

        expect do
          result = described_class.call(name: 'John Smith', council:)
        end.to change(Person, :count).by(1)

        expect(result).not_to eq(unrelated_person)
      end
    end

    it 'applies the same name cleanup as People::RecordPerson (e.g. stripping honorifics)' do
      described_class.call(name: 'Dr John Smith OAM', council:)

      expect(Person.exists?(name: 'john smith')).to be(true)
    end
  end
end
