require 'rails_helper'

RSpec.describe Groups::Record::RecordGroupWithExternalId, type: :service do
  subject(:call_service) do
    described_class.new(name:, identifier:, source:, id_attribute:).call
  end

  let(:name) { 'Acme Foundation' }
  let(:identifier) { 'ACNC-123' }
  let(:source) { 'acnc' }
  let(:id_attribute) { 'acnc_id' }

  describe '#call' do
    context 'when a group exists with the external identifier' do
      let!(:group) { FactoryBot.create(:group, name: 'Acme Foundation Ltd') }

      before do
        group.public_send(:"#{id_attribute}=", identifier)
      end

      it 'returns that group and does not create another' do
        expect { expect(call_service).to eq(group) }.not_to change(Group, :count)
      end

      it 'adds the searched name as a trading name when names differ' do
        expect { call_service }.to change { group.reload.trading_names.where(name: name.downcase).count }.by(1)
      end
    end

    context 'when no group exists with the external identifier' do
      context 'and exactly one group exists with the name' do
        let!(:group) { FactoryBot.create(:group, name:) }

        it 'returns the existing group and appends the identifier' do
          expect { expect(call_service).to eq(group) }.not_to change(Group, :count)

          expect(group.reload.public_send(id_attribute)).to eq(identifier)
          expect(group.trading_names.where(name:).exists?).to be(true)
        end

        context 'when the existing identifier differs' do
          let!(:group) { FactoryBot.create(:group, name:) }

          before do
            group.public_send(:"#{id_attribute}=", 'ACNC-OLD')
          end

          it 'creates a new group with the provided identifier' do
            expect { call_service }.to change(Group, :count).by(1)

            created_group = Group.order(:id).last
            expect(created_group.public_send(id_attribute)).to eq(identifier)
            expect(created_group.name).to eq(name.downcase)
          end
        end

        context 'when multiple similarly named groups are detected' do
          before do
            Group.create!(name: name)
            Group.create!(name: name)

            allow(NewRelic::Agent).to receive(:notice_error)
          end

          it 'logs to NewRelic and creates a new group' do
            expect { call_service }.to change(Group, :count).by(1)
            expect(NewRelic::Agent).to have_received(:notice_error).with("Cannot Disambiguate Group name: #{name}")
          end
        end
      end

      context 'and no group exists with the name' do
        it 'creates a new group with identifier and trading name' do
          expect { call_service }.to change(Group, :count).by(1)

          group = Group.order(:id).last
          expect(group.name).to eq(name.downcase)
          expect(group.public_send(id_attribute)).to eq(identifier)
          expect(group.trading_names.where(name:).exists?).to be(true)
        end

        context 'when advisory-lock save raises a validation error' do
          before do
            error = ActiveRecord::RecordInvalid.new(Group.new)
            allow_any_instance_of(described_class).to receive(:save_inside_advisory_lock!).and_raise(error)
          end

          it 'raises the validation error' do
            expect { call_service }.to raise_error(ActiveRecord::RecordInvalid)
          end
        end
      end
    end
  end
end
