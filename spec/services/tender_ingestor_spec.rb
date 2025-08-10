require 'rails_helper'
require 'spec_helper'

# rubocop:disable Layout/LineLength
RSpec.describe TenderIngestor, type: :service do
  subject(:service) { described_class.new }

  before do
    allow(Faraday).to receive(:new).and_return(double('Faraday::Connection', get: response))
    allow(response).to receive(:body).and_return(response_body)
    allow(response).to receive(:success?).and_return(true)
  end

  let(:response) { double('Faraday::Response', status: 200) }
  let(:response_body) { File.read(Rails.root.join('spec', 'fixtures', 'contract_last_modified.json')) }

  xit 'uses Faraday to fetch the tender data' do
    expect(Faraday).to receive(:new).with(url: anything)
    service
  end

  describe '#process_for_url' do
    context 'when the response is a subsequent page, which has contracts and amendments' do
      let(:response_body) { File.read(Rails.root.join('spec', 'fixtures', 'contract_last_modified_subsequent_page.json')) }

      context 'when an initial contract is present in the response' do
        context 'and that contract does not already exist in the database' do
          it 'creates a new transfer and individual contract' do
            described_class.process_for_url(url: 'url')

            taker = Group.find_by(name: 'Hitachi Vantara Australia Pty Ltd')
            giver = Group.find_by(name: 'Services Australia')

            expect(giver).to be_present
            expect(taker).to be_present

            eofy_2020 = Date.new(2020, 6, 30)
            transfer = Transfer.find_by(giver: giver, taker: taker, effective_date: eofy_2020)

            expect(transfer).to be_present

            individual_transaction = IndividualTransaction.find_by(external_id: 'prod-63e175f2bc1c4e0bae8ba6ab54bc89eb-64b9e8e38ec83d708907f7310ca99e1f')

            expect(individual_transaction).to be_present
            expect(individual_transaction.transfer).to eq(transfer) # the containing transfer for the financial year
            expect(individual_transaction.amount).to eq(10259869.35) # the value of the initial contract
            expect(individual_transaction.effective_date).to eq(Date.new(2020, 4, 7)) # date of the individual transaction
            expect(individual_transaction.description).to eq('ICT Hardware') # description of the individual transaction
            expect(individual_transaction.contract_id).to eq('CN3671507') # the contract ID
          end
        end

        context 'and that contract already exists in the database' do
        end

        context 'and the service is called again with the same date' do
        end
      end
    end
  end

  describe '#fetch_contracts_for_url' do
    # TEMP - this SHOULD BE a private method
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
        contract_id: 'CN4161550',
        date: '2025-06-20T08:27:34Z',
        ocid: 'prod-b33dcd848f4840a4958058b1cacd1860',
        purchaser_abn: '47065634525',
        purchaser_name: 'Department of Foreign Affairs and Trade',
        supplier_abn: '',
        supplier_name: 'TECRAM SARL',
        tag: 'contract',
        value: '13980.88',
        description: 'General Waste Machinery'
      )
    end

    it 'returns an array of contract purchasers' do
      contracts = described_class.new.fetch_contracts_for_url(url: url)
      expect(contracts.second).to include(
        contract_id: 'CN4161551',
        date: '2025-06-20T08:27:34Z',
        ocid: 'prod-538a2b76057c4ceb835c9fa989056b98',
        purchaser_abn: '47065634525',
        purchaser_name: 'Department of Foreign Affairs and Trade',
        supplier_abn: '90629363328',
        supplier_name: 'CyberCx Pty Ltd',
        tag: 'contract',
        value: '346856.40',
        description: 'Temporary Personnel Services'
      )
    end

    context 'when the response is a subsequent page, which has contracts and amendments' do
      let(:response_body) { File.read(Rails.root.join('spec', 'fixtures', 'contract_last_modified_subsequent_page.json')) }

      context 'when an initial contract is present in the response' do
        context 'and that contract does not already exist in the database' do
        end

        context 'and that contract already exists in the database' do
        end

        context 'and the service is called again with the same date' do
        end
      end
    end
  end

  describe '#record_release' do
    # TEMP - this SHOULD BE a private method
    let(:description) { 'A Transfer of Stuff' }
    let(:purchaser_name) { 'Department of Australia'}
    it 'is a foo' do

      body = JSON.parse(response.body)
      first_release = body['releases'].first

      release = {
        ocid: "release['ocid']",
        date: Date.today,
        value: 1001,
        contract_id: 'CN4160732',
        tag: "'release['tag'].first'",
        supplier_name: 'Accounting Consulting Guys',
        supplier_abn: 'abn abn',
        purchaser_name: purchaser_name,
        purchaser_abn: '999123123',
        description: 'A Transfer of stuff'
      }

      service.record_release(release)

      transfer = Transfer.last

      expect(transfer.giver.name).to eq(purchaser_name)
    end
  end
end
# rubocop:enable Layout/LineLength
