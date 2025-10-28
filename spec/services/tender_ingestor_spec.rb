require 'rails_helper'
require 'spec_helper'
require 'tender_ingestor'

RSpec.describe TenderIngestor, type: :service do
  subject(:service) { described_class.new }

  # rubocop:disable RSpec/VerifiedDoubles
  before do
    allow(Faraday).to receive(:new).and_return(double('Faraday::Connection', get: response))
    allow(response).to receive_messages(body: response_body, success?: true)

    allow(IngestContractsUrlJob).to receive(:perform_async).and_return('jid:123')
    allow(IngestContractsUrlJob).to receive(:perform_in)
  end

  let(:response) { double('Faraday::Response', status: 200) }
  let(:response_body) { Rails.root.join('spec/fixtures/contract_last_modified.json').read }
  # rubocop:enable RSpec/VerifiedDoubles

  describe '#process_for_url' do
    context 'when the response is a subsequent page, which has contracts and amendments' do
      let(:response_body) { Rails.root.join('spec/fixtures/contract_last_modified_subsequent_page.json').read }
      let(:original_release_id) { 'prod-63e175f2bc1c4e0bae8ba6ab54bc89eb-64b9e8e38ec83d708907f7310ca99e1f' }
      let(:original_release_date) { Date.new(2020, 4, 7) }
      let(:eofy_twenty_twenty) { Date.new(2020, 6, 30) }
      let(:original_release_value) { 10_259_869.35 }
      let(:original_release_description) { 'ICT Hardware' }
      let(:original_release_contract_id) { 'CN3671507' }
      let(:abn) { '65005610079' }

      let(:supplier_name) { 'Hitachi Vantara Australia Pty Ltd' }
      let(:purchaser_name) { 'Services Australia' }

      before do
        allow(IngestSingleContractJob).to receive(:perform_async).and_return('jid:456')
      end

      it "calls fetch_contracts_for_url and processes each contract's individual transactions" do
        described_class.process_for_url(url: 'url')
        expect(IngestSingleContractJob).to have_received(:perform_async).at_least(:once)
      end

      it 'queues the next page for processing' do
        described_class.process_for_url(url: 'url')

        expect(IngestContractsUrlJob).to have_received(:perform_in)
                                     .with(
                                        30.seconds,
                                        %r{\Ahttps://api\.tenders\.gov\.au/ocds/findByDates/contractLastModified}
                                     )
      end
    end
  end
end
