require 'rails_helper'

RSpec.describe AusTender::TenderDownloader, type: :service do
  subject(:downloader) { described_class.new }

  let(:connection) { double('Faraday::Connection', get: response) } # rubocop:disable RSpec/VerifiedDoubles
  let(:response) { double('Faraday::Response') } # rubocop:disable RSpec/VerifiedDoubles

  before do
    allow(Faraday).to receive(:new).and_return(connection)
  end

  describe '#download' do
    context 'when the request succeeds and there is a next page (happy path)' do
      let(:body_json) { { 'releases' => [{ 'id' => 1 }], 'links' => { 'next' => 'https://example.com/page2' } }.to_json }
      let(:response) { double('Faraday::Response', success?: true, status: 200, body: body_json) } # rubocop:disable RSpec/VerifiedDoubles

      it 'returns success, status, parsed body and the next page url' do
        result = downloader.download('https://example.com/page1')

        expect(result).to eq(
          success: true,
          status: 200,
          body: { 'releases' => [{ 'id' => 1 }], 'links' => { 'next' => 'https://example.com/page2' } },
          next_page: 'https://example.com/page2'
        )
      end
    end

    context 'when the request succeeds with no next page' do
      let(:body_json) { { 'releases' => [], 'links' => {} }.to_json }
      let(:response) { double('Faraday::Response', success?: true, status: 200, body: body_json) } # rubocop:disable RSpec/VerifiedDoubles

      it 'reports next_page as nil' do
        result = downloader.download('https://example.com/page1')

        expect(result).to eq(success: true, status: 200, body: { 'releases' => [], 'links' => {} }, next_page: nil)
      end
    end

    context 'when the request fails with a JSON error body' do
      let(:response) do
        double('Faraday::Response', success?: false, status: 500, body: '{"error":"server error"}', :[] => nil) # rubocop:disable RSpec/VerifiedDoubles
      end

      it 'returns the failure status and the parsed error body' do
        result = downloader.download('https://example.com/page1')

        expect(result).to eq(success: nil, status: 500, body: { 'error' => 'server error' })
      end
    end

    context 'when the request fails with a non-JSON error body' do
      let(:response) { double('Faraday::Response', success?: false, status: 500, body: 'Internal Server Error', :[] => nil) } # rubocop:disable RSpec/VerifiedDoubles

      # FINDING (pre-existing, not introduced by this change): #download calls #body
      # unconditionally even on the failure branch, and #body always JSON-parses the
      # response. A non-JSON error body (e.g. a plain-text 500 page) raises here
      # instead of #download returning a clean failure hash.
      it 'raises JSON::ParserError instead of returning a failure hash' do
        expect { downloader.download('https://example.com/page1') }.to raise_error(JSON::ParserError)
      end
    end
  end

  describe '#success' do
    it 'returns false before any download has happened' do
      expect(downloader.success).to be(false)
    end
  end
end
