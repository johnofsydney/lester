require 'rails_helper'
# LinkedInProfileGetter uses CapitalizeNames without requiring it itself - in the full
# app this is satisfied by another file (e.g. People::RecordPerson) requiring it first.
# Required explicitly here so this spec doesn't depend on load order.
require 'capitalize_names'

RSpec.describe LinkedInProfileGetter, type: :service do
  subject(:getter) { described_class.new(person) }

  let(:person) { create(:person, linkedin_url: 'https://linkedin.com/in/jane-example') }

  describe '#parse_date' do
    it 'builds a Date from a {year, month, day} hash' do
      date = getter.parse_date({ 'year' => 2022, 'month' => 7, 'day' => 1 })

      expect(date).to eq(Date.new(2022, 7, 1))
    end

    it 'returns nil for a blank hash' do
      expect(getter.parse_date(nil)).to be_nil
      expect(getter.parse_date({})).to be_nil
    end

    it 'returns nil instead of raising for an invalid date' do
      expect(getter.parse_date({ 'year' => 2022, 'month' => 2, 'day' => 31 })).to be_nil
    end
  end

  describe '#handle_experience' do
    it 'records the group, membership and position, upcasing a CEO title (happy path)' do
      experience = {
        'company' => 'Example Co',
        'title' => 'ceo',
        'starts_at' => { 'year' => 2020, 'month' => 1, 'day' => 1 },
        'ends_at' => { 'year' => 2021, 'month' => 1, 'day' => 1 }
      }

      expect { getter.handle_experience(experience) }
        .to change(Group, :count).by(1)
        .and change(Membership, :count).by(1)
        .and change(Position, :count).by(1)

      position = Position.last
      expect(position.title).to eq('CEO')
      expect(position.start_date).to eq(Date.new(2020, 1, 1))
      expect(position.end_date).to eq(Date.new(2021, 1, 1))
      expect(position.evidence).to eq(person.linkedin_url)
      expect(position.membership.evidence).to eq(person.linkedin_url)
      expect(position.membership.group.name).to eq('example co')
    end

    it 'leaves the title nil (rather than upcasing nothing) when there is no title' do
      experience = { 'company' => 'Example Co', 'title' => nil, 'starts_at' => nil, 'ends_at' => nil }

      getter.handle_experience(experience)

      expect(Position.count).to eq(0)
    end
  end

  describe '#perform' do
    let(:connection) { double('Faraday::Connection', get: response) } # rubocop:disable RSpec/VerifiedDoubles
    let(:response_body) do
      {
        'experiences' => [
          {
            'company' => 'Example Co',
            'title' => 'Engineer',
            'starts_at' => { 'year' => 2020, 'month' => 1, 'day' => 1 },
            'ends_at' => nil
          }
        ]
      }.to_json
    end
    let(:response) { double('Faraday::Response', success?: true, body: response_body) } # rubocop:disable RSpec/VerifiedDoubles

    before do
      allow(Faraday).to receive(:new).and_return(connection)
    end

    it 'records each experience and marks the person as linkedin_ingested today (happy path)' do
      expect { getter.perform }.to change(Membership, :count).by(1)

      expect(person.reload.linkedin_ingested).to eq(Time.zone.today)
    end

    it 'returns true' do
      expect(getter.perform).to be(true)
    end

    context 'when the request is not successful' do
      let(:response) { double('Faraday::Response', success?: false) } # rubocop:disable RSpec/VerifiedDoubles

      it 'returns nil without recording anything' do
        expect(getter.perform).to be_nil
        expect(Membership.count).to eq(0)
      end
    end
  end
end
