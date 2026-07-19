require 'rails_helper'

RSpec.describe OpenAustralia::IngestPerson, type: :service do
  let(:fixture_dir) { Rails.root.join('spec/fixtures/open_australia') }
  let(:api_client) { instance_double(OpenAustralia::ApiClient) }

  before do
    allow(OpenAustralia::ApiClient).to receive(:new).and_return(api_client)
  end

  describe 'a representative-only person (Anthony Albanese)' do
    subject(:call) { described_class.call(person_id: '10007') }

    let(:rep_terms) { JSON.parse(File.read(fixture_dir.join('get_representative_albanese.json'))) }

    before do
      allow(api_client).to receive_messages(get_representative: rep_terms, get_senator: [])
    end

    it 'creates the person' do
      expect { call }.to change(Person, :count).by(1)
      expect(Person.last.name).to eq('anthony albanese')
    end

    it 'sets the open_australia external identifier' do
      person = call
      expect(person.open_australia_id).to eq('10007')
    end

    it 'stores the representative terms as open_australia_data' do
      person = call
      expect(person.open_australia_data).to eq(rep_terms)
    end

    it 'sets open_australia_data_fetched_at to the fetch time' do
      person = call
      expect(person.open_australia_data_fetched_at).to be_within(2.seconds).of(Time.current)
    end

    it 'creates no Membership or Position records' do
      call
      expect(Membership.count).to eq(0)
      expect(Position.count).to eq(0)
    end

    context 'when called a second time (re-fetch)' do
      it 'does not create a duplicate person and overwrites open_australia_data' do
        call
        expect { described_class.call(person_id: '10007') }.not_to change(Person, :count)
      end
    end
  end

  describe 'a senator-only person (Carol Brown)' do
    subject(:call) { described_class.call(person_id: '10071') }

    let(:sen_terms) { JSON.parse(File.read(fixture_dir.join('get_senator_carol_brown.json'))) }

    before do
      allow(api_client).to receive_messages(get_representative: [], get_senator: sen_terms)
    end

    it 'creates the person' do
      expect { call }.to change(Person, :count).by(1)
      expect(Person.last.name).to eq('carol brown')
    end

    it 'stores the senator terms as open_australia_data' do
      person = call
      expect(person.open_australia_data).to eq(sen_terms)
    end
  end

  describe 'a person who has served in both chambers (Barnaby Joyce)' do
    subject(:call) { described_class.call(person_id: '10350') }

    let(:rep_terms) { JSON.parse(File.read(fixture_dir.join('get_representative_barnaby_joyce.json'))) }
    let(:sen_terms) { JSON.parse(File.read(fixture_dir.join('get_senator_barnaby_joyce.json'))) }

    before do
      allow(api_client).to receive_messages(get_representative: rep_terms, get_senator: sen_terms)
    end

    it 'merges terms from both houses into open_australia_data' do
      person = call

      expect(person.open_australia_data.length).to eq(3)
      expect(person.open_australia_data.map { |t| t['house'] }).to contain_exactly('1', '1', '2')
    end

    it 'orders the merged terms chronologically by entered_house' do
      person = call

      entered_dates = person.open_australia_data.map { |t| t['entered_house'] }
      expect(entered_dates).to eq(entered_dates.sort)
    end

    it 'uses the most recent term for the full_name lookup' do
      person = call
      expect(person.name).to eq('barnaby joyce')
    end
  end

  describe 'a person with no terms in either house' do
    subject(:call) { described_class.call(person_id: '99999') }

    before do
      allow(api_client).to receive_messages(get_representative: [], get_senator: [])
    end

    it 'returns nil and creates no person' do
      expect { call }.not_to change(Person, :count)
      expect(call).to be_nil
    end
  end
end
