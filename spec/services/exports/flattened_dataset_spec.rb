require 'rails_helper'

RSpec.describe Exports::FlattenedDataset, type: :service do
  let(:uploads) { {} }

  before do
    allow(Exports::S3Client).to receive(:upload) { |key, body| uploads[key] = body }
  end

  def rows(key) = JSON.parse(uploads.fetch(key))

  describe '#call' do
    it 'uploads a flattened row per person with no cached summary' do
      person = create(:person, name: 'Jane Donor')

      described_class.call

      row = rows('data-export/people.json').find { |r| r['id'] == person.id }
      expect(row).to include('name' => person.name, 'type' => 'Person')
    end

    it 'uploads a flattened row per group, reading fields out of its cached summary' do
      group = create(:group, name: 'Acme Pty Ltd',
                             cached_summary: { 'money_in' => 500, 'money_out' => 10 },
                             cached_summary_timestamp: Time.zone.now)

      described_class.call

      row = rows('data-export/groups.json').find { |r| r['id'] == group.id }
      expect(row).to include('name' => group.name, 'money_in' => 500, 'money_out' => 10)
    end
  end
end
