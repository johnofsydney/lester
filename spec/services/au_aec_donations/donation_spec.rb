require 'rails_helper'

describe AuAecDonations::Donation do
  subject(:donation) { described_class.new(row_hash) }

  let(:row_hash) do
    {
      'ViewName' => 'Annual Donor Donation Made',
      'RegistrationCode' => 'BMQHL5',
      'ReturnId' => 82_589,
      'ReturnTypeCode' => 'federaldonororganisation',
      'ReturnTypeDescription' => 'Organisation Donor Return',
      'FinancialYear' => '2024-25',
      'ClientFileId' => 18_051,
      'CurrentClientName' => 'Australian Energy Producers',
      'ReturnClientName' => 'Australian Energy Producers',
      'DonationMadeToName' => 'Australian Labor Party (Western Australian Branch)',
      'DonationMadeToClientFileId' => 53,
      'DonationMadeToClientType' => 'politicalparty',
      'TransactionDate' => '2024-07-01T00:00:00',
      'Amount' => 5500,
      'FinancialRecordType' => 'donationmade'
    }
  end

  it 'has the correct attributes' do
    expect(donation.amount).to eq(5500)
    expect(donation.donor_name).to eq('Australian Energy Producers')
    expect(donation.recipient_name).to eq('Australian Labor Party (Western Australian Branch)')
    expect(donation.date).to eq(Date.new(2024, 7, 1))
    expect(donation.donor_aec_id).to eq(18_051)
    expect(donation.recipient_aec_id).to eq(53)
    expect(donation.financial_year).to eq('2024-25')
    expect(donation.return_id).to eq(82_589)
  end
end
