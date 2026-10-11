require 'rails_helper'

RSpec.describe AcncCharities::CsvDownloader, type: :service do
  subject(:downloader) { described_class.new }

  let(:connection) { double('Faraday::Connection', get: response) } # rubocop:disable RSpec/VerifiedDoubles
  let(:response) { double('Faraday::Response') } # rubocop:disable RSpec/VerifiedDoubles

  before do
    allow(Faraday).to receive(:new).and_return(connection)
  end

  describe '#download' do
    context 'when the request succeeds (happy path)' do
      let(:response) { double('Faraday::Response', success?: true, status: 200, body: 'name,abn\nAcme,123') } # rubocop:disable RSpec/VerifiedDoubles

      it 'returns success, status and body from the response' do
        result = downloader.download('https://example.com/charities.csv')

        expect(result).to eq(success: true, status: 200, body: 'name,abn\nAcme,123')
      end
    end

    context 'when the request fails' do
      let(:response) do
        double('Faraday::Response', success?: false, status: 404, body: 'not found', :[] => nil) # rubocop:disable RSpec/VerifiedDoubles
      end

      it 'returns the failure status and body' do
        result = downloader.download('https://example.com/missing.csv')

        # `success?` false with no secondary `[:success]` falls through to nil, not false
        # (`false || nil` is nil) - this is existing behaviour, documented here as-is.
        expect(result).to eq(success: nil, status: 404, body: 'not found')
      end
    end
  end

  describe '#success' do
    it 'returns false before any download has happened' do
      expect(downloader.success).to be(false)
    end
  end

  describe '#status' do
    it 'returns nil before any download has happened' do
      expect(downloader.status).to be_nil
    end
  end

  describe '#body' do
    it 'returns nil before any download has happened' do
      expect(downloader.body).to be_nil
    end
  end
end
