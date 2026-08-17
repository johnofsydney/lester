require 'rails_helper'

RSpec.describe People::RecordCouncilElectionData, type: :service do
  let(:person) { FactoryBot.create(:person, name: 'Derek Schoen') }
  let(:observation) do
    {
      state: :nsw,
      council_name: 'Federation Council',
      council_slug: 'federation',
      cycle: 'LG2401',
      declared_date: Date.new(2024, 10, 1),
      party: 'Independent',
      source_url: 'https://pastvtr.elections.nsw.gov.au/LG2401/federation/councillor'
    }
  end

  describe '#call' do
    context 'when this observation has not been recorded before' do
      it 'appends it to council_election_data' do
        described_class.call(person:, observation:)

        expect(person.reload.council_election_data.size).to eq(1)
        recorded = person.council_election_data.first
        expect(recorded['state']).to eq('nsw')
        expect(recorded['council_slug']).to eq('federation')
        expect(recorded['cycle']).to eq('LG2401')
        expect(recorded['declared_date']).to eq('2024-10-01')
      end

      it 'sets council_election_data_updated_at' do
        described_class.call(person:, observation:)

        expect(person.reload.council_election_data_updated_at).to be_present
      end
    end

    context 'when the same state/council/cycle observation is recorded again' do
      before { described_class.call(person:, observation:) }

      it 'does not append a duplicate' do
        expect do
          described_class.call(person:, observation:)
        end.not_to(change { person.reload.council_election_data.size })
      end
    end

    context 'when the person already has an observation for a different cycle' do
      before { described_class.call(person:, observation:) }

      it 'appends the new one alongside the existing one' do
        other_observation = observation.merge(cycle: 'LG2101', declared_date: Date.new(2021, 12, 4))

        described_class.call(person:, observation: other_observation)

        expect(person.reload.council_election_data.size).to eq(2)
      end
    end
  end
end
