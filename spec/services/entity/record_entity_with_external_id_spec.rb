require 'rails_helper'

RSpec.describe Entity::RecordEntityWithExternalId, type: :service do
  subject(:call_service) do
    described_class.new(name:, identifier:, source:, id_attribute:, klass:).call
  end

  let(:name) { 'Acme Foundation' }
  let(:identifier) { 'ACNC-123' }
  let(:source) { 'acnc' }
  let(:id_attribute) { 'acnc_id' }

  describe '#call' do
    context 'when recording a group' do
      let(:klass) { 'Group' }

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

              # allow(NewRelic::Agent).to receive(:notice_error)
            end

            it 'logs to NewRelic and creates a new group' do
              expect { call_service }.to change(Group, :count).by(1)
              # expect(NewRelic::Agent).to have_received(:notice_error).with("Cannot Disambiguate Group name: #{name}")
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
        end
      end
    end

    context 'when recording a person' do
      let(:klass) { 'Person' }

      context 'when a person exists with the external identifier' do
        let!(:person) { FactoryBot.create(:person, name: 'Jane Citizen') }

        before do
          person.public_send(:"#{id_attribute}=", identifier)
        end

        it 'returns that person and does not create another' do
          expect { expect(call_service).to eq(person) }.not_to change(Person, :count)
        end
      end

      context 'when no person exists with the external identifier' do
        context 'and exactly one person exists with the name' do
          let!(:person) { FactoryBot.create(:person, name:) }

          it 'returns the existing person and appends the identifier' do
            expect { expect(call_service).to eq(person) }.not_to change(Person, :count)
            expect(person.reload.public_send(id_attribute)).to eq(identifier)
            expect(person.trading_names.where(name:).exists?).to be(true)
          end
        end

        context 'and no person exists with the name' do
          it 'creates a new person with identifier and trading name' do
            expect { call_service }.to change(Person, :count).by(1)

            person = Person.order(:id).last
            expect(person.name).to eq(name.downcase)
            expect(person.public_send(id_attribute)).to eq(identifier)
            expect(person.trading_names.where(name:).exists?).to be(true)
          end
        end
      end
    end
  end
end
