require 'rails_helper'

describe AuAecDonations::DonationObject::ReferendumDonation do
  subject(:donation) { described_class.new(row_hash) }

  context 'when the donation is a referendum donation' do
    let(:row_hash) do
      {
        "ViewName" => "Referendum Donor Donation Made",
        "RegistrationCode" => "BIHVR0",
        "ReturnId" => 67518,
        "ReturnTypeCode" => "federalrefdonororganisation",
        "ReturnTypeDescription" => "Referendum Organisation Donor Return",
        "EventDescription" => "2023 Referendum",
        "EventId" => "29581",
        "ClientFileId" => 47503,
        "CurrentClientName" => "Aarnja Limited",
        "ReturnClientName" => "Aarnja Limited",
        "DonationMadeToName" => "Kimberley Land Council",
        "DonationMadeToClientFileId" => 47209,
        "DonationMadeToClientType" => "referendumentity",
        "TransactionDate" => "2023-08-24T00:00:00",
        "Amount" => 100000,
        "FinancialRecordType" => "donationmadetoreferendum"
      }
    end

    it 'has the correct attributes' do
      expect(donation.amount).to eq(100000)
      expect(donation.donor_name).to eq('Aarnja Limited')
      expect(donation.recipient_name).to eq('Kimberley Land Council')
      expect(donation.date).to eq(Date.new(2023, 8, 24))
      expect(donation.donor_aec_id).to eq('47503')
      expect(donation.recipient_aec_id).to eq('47209')
      # expect(donation.financial_year).to eq('2024-25')
      expect(donation.return_id).to eq('67518')
    end
  end
end
