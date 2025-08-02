require 'rails_helper'
require 'spec_helper'

RSpec.describe TenderIngestor, type: :service do
  subject(:service) { described_class.new }

  before do
    allow(Faraday).to receive(:new).and_return(double('Faraday::Connection', get: response))
    allow(response).to receive(:body).and_return(response_body)
    allow(response).to receive(:success?).and_return(true)
  end

  let(:response) { double('Faraday::Response', status: 200) }
  # rubocop:disable Layout/LineLength
  let(:response_body) do
    File.read(Rails.root.join('spec', 'fixtures', 'contract_last_modified.json'))
  end

  xit 'uses Faraday to fetch the tender data' do
    expect(Faraday).to receive(:new).with(url: anything)
    service
  end

  describe '#fetch_contracts_for_date' do
    let(:date) { Date.parse('2023-10-01') }
    let(:url) { "https://api.tenders.gov.au/ocds/findByDates/contractLastModified/#{date.beginning_of_day.iso8601}/#{date.end_of_day.iso8601}" }

    it 'fetches contracts for the given date' do
      contracts = described_class.new.fetch_contracts_for_url(url: url)
      expect(contracts).to be_an(Array)
    end

    it 'returns an array of contracts' do
      contracts = described_class.new.fetch_contracts_for_url(url: url)
      expect(contracts).to be_an(Array)
    end

    it 'returns an array of contract suppliers' do
      contracts = described_class.new.fetch_contracts_for_url(url: url)

      expect(contracts.first).to include(
        contract_id: "CN4161550",
        date: "2025-06-20T08:27:34Z",
        ocid: "prod-b33dcd848f4840a4958058b1cacd1860",
        purchaser_abn: "47065634525",
        purchaser_name: "Department of Foreign Affairs and Trade",
        supplier_abn: "",
        supplier_name: "TECRAM SARL",
        tag: "contract",
        value: "13980.88",
        description: "General Waste Machinery",
      )
    end

    it 'returns an array of contract purchasers' do
      contracts = described_class.new.fetch_contracts_for_url(url: url)
      expect(contracts.second).to include(
        contract_id: "CN4161551",
        date: "2025-06-20T08:27:34Z",
        ocid: "prod-538a2b76057c4ceb835c9fa989056b98",
        purchaser_abn: "47065634525",
        purchaser_name: "Department of Foreign Affairs and Trade",
        supplier_abn: "90629363328",
        supplier_name: "CyberCx Pty Ltd",
        tag: "contract",
        value: "346856.40",
        description: "Temporary Personnel Services",
      )
    end
  end

  describe '#record_contract' do
  let(:description) { 'A Transfer of Stuff' }
  let(:purchaser_name) { 'Department of Australia'}
    it "is a foo" do

      body = JSON.parse(response.body)
      first_release = body['releases'].first

      contract = {
        ocid: "release['ocid']",
        date: Date.today,
        value: 1001,
        contract_id: 'CN4160732',
        tag: "'release['tag'].first'",
        supplier_name: 'Accounting Consulting Guys',
        supplier_abn: 'abn abn',
        purchaser_name: purchaser_name,
        purchaser_abn: '999123123',
        description: 'A Transfer of stuff',
      }

      service.record_contract(contract)

      transfer = Transfer.last

      expect(transfer.giver.name).to eq(purchaser_name)
    end

  end
end