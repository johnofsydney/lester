require 'rails_helper'

RSpec.describe Exports::UploadSummary, type: :service do
  describe '#call' do
    before do
      FactoryBot.create_list(:group, 2)
      FactoryBot.create(:person)
      allow(Exports::S3Client).to receive(:upload)
    end

    it 'uploads a summary.json with current group and person counts' do
      described_class.call

      expect(Exports::S3Client).to have_received(:upload).with('summary.json', { groups: 2, people: 1 }.to_json)
    end
  end
end
