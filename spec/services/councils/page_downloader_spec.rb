require 'rails_helper'

RSpec.describe Councils::PageDownloader, type: :service do
  subject(:call_service) { described_class.call(url) }

  let(:url) { 'https://example.com/some-page' }
  let(:response) { double('Faraday::Response') } # rubocop:disable RSpec/VerifiedDoubles
  let(:connection) { double('Faraday::Connection', get: response) } # rubocop:disable RSpec/VerifiedDoubles
  let(:config) { double('Faraday::ConnectionOptions').as_null_object } # rubocop:disable RSpec/VerifiedDoubles

  before do
    allow(Faraday).to receive(:new).and_yield(config).and_return(connection)
  end

  context 'when the request succeeds' do
    let(:response) { double('Faraday::Response', success?: true, body: '<html>hello</html>') } # rubocop:disable RSpec/VerifiedDoubles

    it 'returns the response body' do
      expect(call_service).to eq('<html>hello</html>')
    end
  end

  context 'when the request returns a non-success status' do
    let(:response) { double('Faraday::Response', success?: false, status: 403) } # rubocop:disable RSpec/VerifiedDoubles

    it 'returns nil' do
      expect(call_service).to be_nil
    end
  end

  context 'when the request raises' do
    before do
      allow(Faraday).to receive(:new).and_raise(Faraday::ConnectionFailed, 'connection failed')
    end

    it 'returns nil rather than raising' do
      expect(call_service).to be_nil
    end
  end
end
