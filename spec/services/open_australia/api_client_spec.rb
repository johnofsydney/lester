require 'rails_helper'

RSpec.describe OpenAustralia::ApiClient, type: :service do
  subject(:client) { described_class.new }

  let(:connection) { instance_double(Faraday::Connection) }
  let(:response) { instance_double(Faraday::Response, success?: true, status: 200, body: '[{"person_id": "10007"}]') }

  before do
    allow(Faraday).to receive(:new).and_return(connection)
    allow(Rails.application.credentials).to receive(:dig).with(:open_australia, :api_key).and_return('test-key')
    allow(connection).to receive(:get).and_return(response)
  end

  # These specs call the real (non-stubbed) ApiClient methods, only faking the HTTP
  # transport — unlike specs elsewhere that stub ApiClient itself via instance_double.
  # That's deliberate: a method-signature regression (e.g. `get` losing its `params`
  # argument) breaks these calls with a real ArgumentError, which a fully-stubbed
  # ApiClient double would silently hide.
  describe '#get_representative' do
    it 'requests getRepresentative with the person id and parses the response' do
      result = client.get_representative('10007')

      expect(connection).to have_received(:get).with('getRepresentative', id: '10007', key: 'test-key', output: 'js')
      expect(result).to eq([{ 'person_id' => '10007' }])
    end
  end

  describe '#get_senator' do
    it 'requests getSenator with the person id and parses the response' do
      client.get_senator('10071')

      expect(connection).to have_received(:get).with('getSenator', id: '10071', key: 'test-key', output: 'js')
    end
  end

  describe '#get_representatives' do
    it 'requests getRepresentatives with no extra params' do
      client.get_representatives

      expect(connection).to have_received(:get).with('getRepresentatives', key: 'test-key', output: 'js')
    end
  end

  describe '#get_senators' do
    it 'requests getSenators with no extra params' do
      client.get_senators

      expect(connection).to have_received(:get).with('getSenators', key: 'test-key', output: 'js')
    end
  end

  context 'when the API responds with a non-success status' do
    let(:response) { instance_double(Faraday::Response, success?: false, status: 500, body: 'boom') }

    it 'raises OpenAustraliaApiError' do
      expect { client.get_representative('10007') }.to raise_error(OpenAustraliaApiError, '500: boom')
    end
  end

  context 'when the API responds with 429 Too Many Requests' do
    let(:response) { instance_double(Faraday::Response, success?: false, status: 429, body: 'slow down') }

    it 'raises OpenAustraliaRateLimitError' do
      expect { client.get_representative('10007') }.to raise_error(OpenAustraliaRateLimitError, '429: slow down')
    end
  end
end
