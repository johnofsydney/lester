require 'rails_helper'

RSpec.describe OpenAustralia::IngestCurrentPoliticians, type: :service do
  subject(:call) { described_class.call }

  let(:fixture_dir) { Rails.root.join('spec/fixtures/open_australia') }
  let(:representatives) { JSON.parse(File.read(fixture_dir.join('get_representatives.json'))) }
  let(:senators) { JSON.parse(File.read(fixture_dir.join('get_senators.json'))) }
  let(:api_client) { instance_double(OpenAustralia::ApiClient) }
  let(:parliament_group) { create(:group, name: 'australian federal parliament') }

  before do
    allow(OpenAustralia::ApiClient).to receive(:new).and_return(api_client)
    allow(api_client).to receive_messages(get_representatives: representatives, get_senators: senators)
    allow(OpenAustralia::IngestPersonJob).to receive(:perform_async).and_return(true)
    allow(Group).to receive(:federal_parliament).and_return(parliament_group)
  end

  it 'enqueues one IngestPersonJob per representative' do
    call
    expect(OpenAustralia::IngestPersonJob).to have_received(:perform_async).with('10007')
    expect(OpenAustralia::IngestPersonJob).to have_received(:perform_async).with('10081')
  end

  it 'enqueues one IngestPersonJob per senator' do
    call
    expect(OpenAustralia::IngestPersonJob).to have_received(:perform_async).with('10071')
    expect(OpenAustralia::IngestPersonJob).to have_received(:perform_async).with('10350')
  end

  it 'enqueues exactly one job per distinct person_id across both rosters' do
    call
    expect(OpenAustralia::IngestPersonJob).to have_received(:perform_async).exactly(4).times
  end

  context 'when the same person_id appears in both rosters' do
    let(:senators) { representatives.first(1) + JSON.parse(File.read(fixture_dir.join('get_senators.json'))) }

    it 'enqueues only one job for that person_id, not two' do
      call
      expect(OpenAustralia::IngestPersonJob).to have_received(:perform_async).with('10007').once
    end
  end

  context 'when the database has a person we still consider current, but who has dropped off the live roster' do
    before do
      person = create(:person)
      person.open_australia_id = '99999'
      create(:membership, member: person, group: parliament_group, end_date: nil)
    end

    it 'still enqueues a job for that person_id' do
      call
      expect(OpenAustralia::IngestPersonJob).to have_received(:perform_async).with('99999')
    end

    it 'enqueues exactly 5 jobs (4 from the roster plus the dropped-off person)' do
      call
      expect(OpenAustralia::IngestPersonJob).to have_received(:perform_async).exactly(5).times
    end
  end

  context 'when a database person considered current is also still on the live roster' do
    before do
      person = create(:person)
      person.open_australia_id = '10007'
      create(:membership, member: person, group: parliament_group, end_date: nil)
    end

    it 'enqueues only one job for that person_id, not two' do
      call
      expect(OpenAustralia::IngestPersonJob).to have_received(:perform_async).with('10007').once
    end
  end

  context 'when a database person has left the parliament group (end_date set)' do
    before do
      person = create(:person)
      person.open_australia_id = '55555'
      create(:membership, member: person, group: parliament_group, end_date: 1.year.ago)
    end

    it 'does not enqueue a job for that person_id' do
      call
      expect(OpenAustralia::IngestPersonJob).not_to have_received(:perform_async).with('55555')
    end
  end
end
