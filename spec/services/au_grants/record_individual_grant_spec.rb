require 'rails_helper'

describe AuGrants::RecordIndividualGrant, type: :service do
  before do
    allow(Transfers::RefreshSingleTransferAmountJob).to receive(:perform_in).and_return(true)
  end

  let(:row) do
    {
      'Agency' => "Attorney-General's Department",
      'GA ID' => 'GA523941',
      'Internal Reference ID' => 'DIDSS000523',
      'GO ID' => 'GO247',
      'Recipient Name' => 'Easyweb Digital Pty Ltd',
      'Recipient ABN' => '79 145 583 099',
      'PBS Program Name' => 'AGD 25/26 1.4 Justice Services',
      'Grant Program' => 'Financial assistance towards legal costs and related expenses',
      'Grant Activity' => 'Financial assistance',
      'Purpose' => 'Financial assistance',
      'One-off/Ad hoc' => 'N',
      'Aggregate' => 'N',
      'Aggregate Reason' => '',
      'Aggregate Number' => nil,
      'Selection Process' => 'Open Competitive',
      'Category' => 'Legal Services',
      'Confidentiality - Contract' => 'N',
      'Confidentiality - Outputs' => 'N',
      'Publish Date' => '2026-01-05',
      'Approval Date' => '2025-11-26',
      'Start Date' => '2025-11-26',
      'End Date' => '2026-10-26',
      'Value (AUD)' => 5_341_639.0,
      'Recipient Suburb' => 'CANBERRA',
      'Recipient Town/City' => 'CANBERRA',
      'Recipient Postcode' => '2600',
      'Recipient State/Territory' => 'ACT',
      'Recipient Country' => 'AUSTRALIA',
      'Delivery State/Territory' => 'ACT',
      'Delivery Postcode' => '2600',
      'Delivery Country' => 'AUSTRALIA',
      'Contact Name' => 'Legal Financial Assistance Casework Section'
    }
  end

  let(:release) { AuGrants::Release.new(row) }
  let(:service) { described_class.new(release) }

  it 'creates an IndividualTransaction with the correct attributes' do
    service.call

    individual_transaction = IndividualTransaction.last
    expect(individual_transaction.amount).to eq(5_341_639.0)
    expect(individual_transaction.effective_date).to eq(Date.new(2026, 1, 5))
    expect(individual_transaction.transaction_type).to eq('government_grant')
    expect(individual_transaction.external_id).to eq('GA523941')
    expect(individual_transaction.evidence).to eq('https://www.grants.gov.au/Ga/Show/GA523941')
  end

  it 'creates the associated records' do
    service.call

    individual_transaction = IndividualTransaction.last
    expect(individual_transaction.giver.name).to eq("attorney-general's department")
    expect(individual_transaction.taker.name).to eq('easyweb digital pty ltd')
    expect(individual_transaction.fine_grained_transaction_category.name).to eq('Legal Services')
    expect(individual_transaction.transfer.transfer_type).to eq('government_grants')
    expect(individual_transaction.transfer.effective_date).to eq(Date.new(2026, 6, 30))
  end

  it 'records the description and recipient location' do
    service.call

    individual_transaction = IndividualTransaction.last
    expect(individual_transaction.description).to eq('Financial assistance towards legal costs and related expenses - Financial assistance - Financial assistance')
    expect(individual_transaction.city).to eq('CANBERRA')
    expect(individual_transaction.state).to eq('ACT')
    expect(individual_transaction.postcode).to eq('2600')
  end

  context 'when the same grant is processed twice' do
    it 'only creates one IndividualTransaction' do
      described_class.new(release).call
      described_class.new(AuGrants::Release.new(row)).call

      expect(IndividualTransaction.count).to eq(1)
    end
  end

  context 'when the grant is aggregate' do
    let(:row) { super().merge('Aggregate' => 'Y') }

    it 'does not create an IndividualTransaction' do
      service.call

      expect(IndividualTransaction.count).to eq(0)
    end
  end

  context 'when the recipient is redacted' do
    let(:row) { super().merge('Recipient Name' => 'n/a', 'Recipient ABN' => 'ABN Exempt') }

    it 'does not create an IndividualTransaction' do
      service.call

      expect(IndividualTransaction.count).to eq(0)
    end
  end

  context 'when the grant is confidential but the recipient is not redacted' do
    let(:row) { super().merge('Confidentiality - Contract' => 'Y') }

    it 'still creates an IndividualTransaction' do
      service.call

      expect(IndividualTransaction.count).to eq(1)
    end
  end

  context 'when the recipient has no ABN' do
    let(:row) { super().merge('Recipient ABN' => 'ABN Exempt') }

    it 'creates the recipient by name only' do
      service.call

      expect(IndividualTransaction.last.taker.name).to eq('easyweb digital pty ltd')
    end
  end
end
