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

  describe '#process_for_url' do
    context 'when the response is a subsequent page, which has contracts and amendments' do
      let(:response_body) { File.read(Rails.root.join('spec', 'fixtures', 'contract_last_modified_subsequent_page.json')) }
      let(:original_release_id) { 'prod-63e175f2bc1c4e0bae8ba6ab54bc89eb-64b9e8e38ec83d708907f7310ca99e1f' }
      let(:original_release_date) { Date.new(2020, 4, 7) }
      let(:eofy_2020) { Date.new(2020, 6, 30) }
      let(:original_release_value) { 10259869.35 }
      let(:original_release_description) { 'ICT Hardware' }
      let(:original_release_contract_id) { 'CN3671507' }
      let(:abn) { '65005610079' }

      let(:supplier_name) { 'Hitachi Vantara Australia Pty Ltd' }
      let(:purchaser_name) { 'Services Australia' }


      context 'when an initial contract is present in the response' do
        context 'and that contract does not already exist in the database' do
          it 'creates a new transfer and individual contract' do
            described_class.process_for_url(url: 'url')

            taker = Group.find_by(name: supplier_name)
            giver = Group.find_by(name: purchaser_name)

            expect(giver).to be_present
            expect(taker).to be_present
            expect(taker.business_number).to eq(abn)

            transfer = Transfer.find_by(giver: giver, taker: taker, effective_date: eofy_2020)
            expect(transfer).to be_present

            individual_transaction = IndividualTransaction.find_by(external_id: original_release_id)

            expect(individual_transaction).to be_present
            expect(individual_transaction.transfer).to eq(transfer) # the containing transfer for the financial year
            expect(individual_transaction.amount).to eq(original_release_value) # the value of the initial contract
            expect(individual_transaction.effective_date).to eq(original_release_date) # date of the individual transaction
            expect(individual_transaction.description).to eq(original_release_description) # description of the individual transaction
            expect(individual_transaction.contract_id).to eq(original_release_contract_id) # the contract ID
          end
        end

        context 'and that contract already exists in the database' do
          let!(:taker) { Group.create(name: supplier_name) }
          let!(:giver) { Group.create(name: purchaser_name) }
          let(:transfer) { Transfer.create(giver:, taker:, effective_date: Date.new(2020, 6, 30)) }

          let!(:individual_transaction) do
            IndividualTransaction.create(
              transfer:,
              external_id: original_release_id,
              amount: original_release_value,
              effective_date: original_release_date,
              description: original_release_description,
              contract_id: original_release_contract_id
            )
          end

          it 'does not create a new individual transaction' do
            expect {
              described_class.process_for_url(url: 'url')
            }.not_to change(IndividualTransaction.where(external_id: original_release_id), :count)
          end
        end

        context 'and the service is called again with the same date' do
          it 'does not create a new individual transaction - it is idempotent' do
            described_class.process_for_url(url: 'url')
            described_class.process_for_url(url: 'url')
            described_class.process_for_url(url: 'url')

            expect(IndividualTransaction.where(external_id: original_release_id).count).to eq(1)
          end
        end
      end

      context 'when there is an initial contract and amendments' do
        let(:contract_amendment_date) { Date.new(2025, 6, 20) }
        let(:first_amendment_release_id) { 'prod-63e175f2bc1c4e0bae8ba6ab54bc89eb-454605a51a843a69b281cdb7b72e662a' }
        let(:second_amendment_release_id) { 'prod-63e175f2bc1c4e0bae8ba6ab54bc89eb-e8ac8686d3503d2699fb5ee1c75d9f42' }
        let(:third_amendment_release_id) { 'prod-63e175f2bc1c4e0bae8ba6ab54bc89eb-473c8aa848b73b37b460d5bf4ea4d342' }
        let(:fourth_amendment_release_id) { 'prod-63e175f2bc1c4e0bae8ba6ab54bc89eb-ac3ddb61c5433b049a3ae862f0ed5c2c' }

        let(:all_release_ids) { [original_release_id, first_amendment_release_id, second_amendment_release_id, third_amendment_release_id, fourth_amendment_release_id] }

        it 'processes the initial contract and amendments' do
          described_class.process_for_url(url: 'url')

          original_release_transaction = IndividualTransaction.find_by(external_id: original_release_id)
          first_amendment_transaction = IndividualTransaction.find_by(external_id: first_amendment_release_id)
          second_amendment_transaction = IndividualTransaction.find_by(external_id: second_amendment_release_id)
          third_amendment_transaction = IndividualTransaction.find_by(external_id: third_amendment_release_id)
          fourth_amendment_transaction = IndividualTransaction.find_by(external_id: fourth_amendment_release_id)

          expect(original_release_transaction).to be_present
          expect(first_amendment_transaction).to be_present
          expect(second_amendment_transaction).to be_present
          expect(third_amendment_transaction).to be_present
          expect(fourth_amendment_transaction).to be_present

          expect(original_release_transaction.effective_date).to eq(original_release_date)
          expect(first_amendment_transaction.effective_date).to eq(contract_amendment_date)
          expect(second_amendment_transaction.effective_date).to eq(contract_amendment_date)
          expect(third_amendment_transaction.effective_date).to eq(contract_amendment_date)
          expect(fourth_amendment_transaction.effective_date).to eq(contract_amendment_date)
        end

        it 'calculates the value of each amendment' do
          described_class.process_for_url(url: 'url')

          original_release_transaction = IndividualTransaction.find_by(external_id: original_release_id)
          first_amendment_transaction = IndividualTransaction.find_by(external_id: first_amendment_release_id)
          second_amendment_transaction = IndividualTransaction.find_by(external_id: second_amendment_release_id)
          third_amendment_transaction = IndividualTransaction.find_by(external_id: third_amendment_release_id)
          fourth_amendment_transaction = IndividualTransaction.find_by(external_id: fourth_amendment_release_id)

          expect(original_release_transaction.amount).to eq(10_259_869.35) # initial contract value
          expect(first_amendment_transaction.amount).to eq(532_070.74) # first amendment value: 10_791_940.09 - 10_259_869.35
          expect(second_amendment_transaction.amount).to eq(854_260.00) # second amendment value: 11_646_200.09 - 10_791_940.09
          expect(third_amendment_transaction.amount).to eq(1_518_042.10) # third amendment value: 13_164_242.19 - (854_260.00 + 532_070.74 + 10259869.35)

        end

        context 'when the supplier does not have an ABN' do
        end
      end
    end

    pending 'handles contracts where the vendor name changes over time'
    context 'when the response includes a long contract where the name of the vendor has changed over time' do
      let(:response_body) { File.read(Rails.root.join('spec', 'fixtures', 'contract_with_vendor_changes_over_time.json')) }

      let(:original_release_id) { 'prod-c5762ddcfc405dfbdf428f47abfa35e6-f64b27a0859135e7846aa5c5e27239a8' }
      let(:first_amendment_release_id) { 'prod-c5762ddcfc405dfbdf428f47abfa35e6-9bdf4acd03593c3bb981d7af9abe7d54' }
      let(:second_amendment_release_id) { 'prod-c5762ddcfc405dfbdf428f47abfa35e6-6b2d253ebee531c2844b00bcd0304380' }

      it 'processes all of the suppliers for a contract' do
        described_class.process_for_url(url: 'url')

        # CN1405771

        original_release_transaction = IndividualTransaction.find_by(external_id: original_release_id)
        first_amendment_transaction = IndividualTransaction.find_by(external_id: first_amendment_release_id)
        second_amendment_transaction = IndividualTransaction.find_by(external_id: second_amendment_release_id)

        expect(original_release_transaction).to be_present
        expect(first_amendment_transaction).to be_present
        expect(second_amendment_transaction).to be_present

        expect(original_release_transaction.transfer.taker.name).to eq('Department of Finance and Deregulation')
        expect(original_release_transaction.transfer.giver.name).to eq('Department of Industry, Science and Resources')
        expect(first_amendment_transaction.transfer.taker.name).to eq('UGL Services Pty Ltd')
        expect(first_amendment_transaction.transfer.giver.name).to eq('Department of Industry, Science and Resources')
        expect(second_amendment_transaction.transfer.taker.other_names).to include('Department of Finance and Administration')
        expect(second_amendment_transaction.transfer.giver.name).to eq('Department of Industry, Science and Resources')
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

  describe '#record_individual_transaction' do
    # This is testing the _Private_ class
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

      # service.record_release(release)
      RecordIndividualTransaction.new(release).perform

      transfer = Transfer.last

      expect(transfer.giver.name).to eq(purchaser_name)
    end
  end
end
# rubocop:enable Layout/LineLength
