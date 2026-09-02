require 'rails_helper'

describe AuGrants::Release, type: :service do
  let(:row) do
    {
      'Agency' => "Attorney-General's Department",
      'GA ID' => 'GA523941',
      'Recipient Name' => 'Easyweb Digital Pty Ltd',
      'Recipient ABN' => '79 145 583 099',
      'Category' => 'Legal Services',
      'Aggregate' => 'N',
      'Confidentiality - Contract' => 'N',
      'Publish Date' => Date.new(2026, 1, 5),
      'Value (AUD)' => 5_341_639.0
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
