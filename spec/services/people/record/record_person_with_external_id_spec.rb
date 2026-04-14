require 'rails_helper'

RSpec.describe People::Record::RecordPersonWithExternalId, type: :service do
  subject(:call_service) do
    described_class.new(name:, identifier:, source:, id_attribute:).call
  end

  let(:name) { 'Jane Citizen' }
  let(:identifier) { 'ACNC-123' }
  let(:source) { 'acnc' }
  let(:id_attribute) { 'acnc_id' }

  describe '#call' do
    context 'when a person exists with the external identifier' do
      let!(:person) { FactoryBot.create(:person, name: 'Jane C. Citizen') }

      before do
        person.public_send(:"#{id_attribute}=", identifier)
      end

      it 'returns that person and does not create another' do
        expect { expect(call_service).to eq(person) }.not_to change(Person, :count)
      end

      it 'adds the searched name as a trading name when names differ' do
        expect { call_service }.to change { person.reload.trading_names.where(name: name.downcase).count }.by(1)
      end
    end

    context 'when no person exists with the external identifier' do
      context 'and exactly one person exists with the name' do
        let!(:person) { FactoryBot.create(:person, name:) }

        it 'returns the existing person and appends the identifier' do
          expect { expect(call_service).to eq(person) }.not_to change(Person, :count)

          expect(person.reload.public_send(id_attribute)).to eq(identifier)
        end

        context 'when the existing identifier differs' do
          let!(:person) { FactoryBot.create(:person, name:) }

          before do
            person.public_send(:"#{id_attribute}=", 'ACNC-OLD')
          end

          it 'creates a new person with the provided identifier' do
            expect { call_service }.to change(Person, :count).by(1)

            created_person = Person.order(:id).last
            expect(created_person.public_send(id_attribute)).to eq(identifier)
            expect(created_person.name).to eq(name.downcase)
          end
        end

        context 'when multiple similarly named people are detected' do
          before do
            Person.create!(name: name.downcase)
            Person.create!(name: name.downcase)
            allow(NewRelic::Agent).to receive(:notice_error)
          end

          it 'logs to NewRelic and creates a new person' do
            expect { call_service }.to change(Person, :count).by(1)
            expect(NewRelic::Agent).to have_received(:notice_error).with("Cannot Disambiguate Person name: #{name}")
          end
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

        context 'when advisory-lock save raises a validation error' do
          before do
            error = ActiveRecord::RecordInvalid.new(Person.new)
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
