require 'rails_helper'

describe AuGrants::Release, type: :service do
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

  let(:release) { described_class.new(row) }

  it 'exposes the core fields' do
    expect(release.ga_id).to eq('GA523941')
    expect(release.agency_name).to eq("Attorney-General's Department")
    expect(release.recipient_name).to eq('Easyweb Digital Pty Ltd')
    expect(release.recipient_abn).to eq('79 145 583 099')
    expect(release.category).to eq('Legal Services')
    expect(release.amount).to eq(5_341_639.0)
    expect(release.effective_date).to eq(Date.new(2026, 1, 5))
    expect(release.evidence).to eq('https://www.grants.gov.au/Ga/Show/GA523941')
  end

  it 'exposes the description and recipient location fields' do
    expect(release.description).to eq('Financial assistance towards legal costs and related expenses - Financial assistance - Financial assistance')
    expect(release.recipient_city).to eq('CANBERRA')
    expect(release.recipient_state).to eq('ACT')
    expect(release.recipient_postcode).to eq('2600')
  end

  it 'is not aggregate and has no redacted recipient' do
    expect(release.aggregate?).to be(false)
    expect(release.redacted_recipient?).to be(false)
  end

  context 'when ABN Exempt' do
    let(:row) { super().merge('Recipient ABN' => 'ABN Exempt') }

    it 'treats the ABN as nil' do
      expect(release.recipient_abn).to be_nil
    end
  end

  context 'when aggregate' do
    let(:row) { super().merge('Aggregate' => 'Y') }

    it 'is aggregate' do
      expect(release.aggregate?).to be(true)
    end
  end

  context 'when the recipient is redacted' do
    let(:row) { super().merge('Recipient Name' => 'n/a', 'Recipient ABN' => 'ABN Exempt') }

    it 'has a redacted recipient' do
      expect(release.redacted_recipient?).to be(true)
    end
  end

  context 'when confidential but the recipient is not redacted' do
    let(:row) { super().merge('Confidentiality - Contract' => 'Y') }

    it 'does not treat it as a redacted recipient' do
      expect(release.redacted_recipient?).to be(false)
    end
  end
end
