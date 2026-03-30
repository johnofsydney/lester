require 'rails_helper'
require 'spec_helper'

RSpec.describe RecordGroup, type: :service do

  let(:group_names) { Group::NAMES }

  let(:mapper) { MapGroupNamesAecDonations.new }

  describe '#initialize' do
    it 'initializes with a name' do
      service = described_class.new('Test Name', nil, mapper)
      expect(service.name).to eq('Test Name')
    end
  end

  describe '.call' do
    context 'when the mapper is AEC Donations' do
      let(:mapper) { MapGroupNamesAecDonations.new }

      before do
        allow(UpdateGroupNamesFromAbnJob).to receive(:perform_async)
      end

      context 'when the group does not already exist' do
        it 'creates a group with the given name' do
          expect { described_class.call('Test Name', mapper:) }.to change(Group, :count).by(1)

          expect(Group.last.name).to eq('test name')
        end

        it 'creates a group with the given name and business number' do
          expect { described_class.call('Test Name', business_number: 'ABN: 123 456 789', mapper:) }.to change(Group, :count).by(1)

          expect(Group.last.name).to eq('test name')
          expect(Group.last.business_number).to eq('123456789')
        end
      end

      context 'when the group already exists' do
        let(:existing_name) { 'Existing Group' }
        let(:business_number) { '123456789' }
        let(:business_number_different_format) { 'ABN: 123 456 789' }

        before do
          Group.create(name: existing_name, business_number: business_number)
        end

        context 'when given only the identical name' do
          it 'does not create a new group' do
            expect { described_class.call(existing_name, mapper:) }.not_to(change(Group, :count))
          end
        end

        context 'when given the identical name and business number' do
          it 'does not create a new group' do
            expect { described_class.call(existing_name, business_number: business_number_different_format, mapper:) }.not_to(change(Group, :count))
          end
        end
      end

      context 'when a group exists with the name' do
        let(:existing_name) { 'Existing Group' }
        let(:business_number) { '123' }

        let!(:existing_group) { Group.create(name: existing_name) }

        it 'returns the existing group' do
          described_class.call(existing_name, business_number:)

          expect(existing_group.reload.business_number).to eq(business_number)
          expect(Group.count).to eq(1)
        end
      end
    end

    describe 'when the mapper is General' do
      let(:mapper) { MapGroupNamesGeneral.new }

      it 'creates a group with the given name' do
        expect { described_class.call('GREENS LIST CLERKING SERVICES', mapper:) }.to change(Group, :count).by(1)

        expect(Group.last.name).to eq('greens list clerking services')
      end
    end
  end
end
