require 'rails_helper'

RSpec.describe People::RecordStateElectionData, type: :service do
  let(:person) { FactoryBot.create(:person, name: 'Tanya Davies') }
  let(:observation) do
    {
      state: :nsw,
      event_id: 'SG2301',
      house: 'LA',
      electorate: 'mulgoa',
      elected: true,
      declared_date: Date.new(2023, 3, 25),
      party: 'The Liberal Party of Australia, New South Wales Division',
      source_url: 'https://pastvtr.elections.nsw.gov.au/SG2301/LA/state/elected'
    }
  end

  describe '#call' do
    context 'when this observation has not been recorded before' do
      it 'appends it to state_election_data' do
        described_class.call(person:, observation:)

        expect(person.reload.state_election_data.size).to eq(1)
        recorded = person.state_election_data.first
        expect(recorded['state']).to eq('nsw')
        expect(recorded['event_id']).to eq('SG2301')
        expect(recorded['house']).to eq('LA')
        expect(recorded['electorate']).to eq('mulgoa')
        expect(recorded['declared_date']).to eq('2023-03-25')
      end

      it 'sets state_election_data_updated_at' do
        described_class.call(person:, observation:)

        expect(person.reload.state_election_data_updated_at).to be_present
      end
    end

    context 'when the same state/event/house/electorate observation is recorded again' do
      before { described_class.call(person:, observation:) }

      it 'does not append a duplicate' do
        expect do
          described_class.call(person:, observation:)
        end.not_to(change { person.reload.state_election_data.size })
      end
    end

    context 'when the person already has an observation for a different event' do
      before { described_class.call(person:, observation:) }

      it 'appends the new one alongside the existing one' do
        other_observation = observation.merge(event_id: 'SG1901', declared_date: Date.new(2019, 3, 23))

        described_class.call(person:, observation: other_observation)

        expect(person.reload.state_election_data.size).to eq(2)
      end
    end
  end
end
