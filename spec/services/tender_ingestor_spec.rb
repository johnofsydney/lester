require 'rails_helper'
require 'spec_helper'

RSpec.describe TenderIngestor, type: :service do
  subject(:service) { described_class.perform }

  before do
    allow(Faraday).to receive(:new).and_return(double('Faraday::Connection', get: response))
    allow(response).to receive(:body).and_return(response_body)
  end

  let(:response) { double('Faraday::Response', status: 200) }
  # rubocop:disable Layout/LineLength
  let(:response_body) do
    File.read(Rails.root.join('spec', 'fixtures', 'tender_response_pretty.json'))
  end

  it 'uses Faraday to fetch the tender data' do
    expect(Faraday).to receive(:new).with(url: anything)
    service
  end
end