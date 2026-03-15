require 'rails_helper'

describe AuAecDonations::DonationObject::ElectionDonation do
  subject(:donation) { described_class.new(row_hash) }

  context 'when the donation is an election donation' do
    let(:row_hash) do
      {
        "ViewName" => "Donations Made Line Item",
        "EventId" => 31496,
        "EventDescription" => "2025 Federal Election",
        "DisclosurePeriodEndDate" => "2025-06-02T00:00:00",
        "DonorCode" => "51277",
        "DonorName" => "ACY Securities Pty Ltd",
        "DonorClientType" => "organisationdonor",
        "ReturnId" => 80518,
        "ReturnTypeCode" => "federaldonorelection",
        "ClientType" => "candidate",
        "ReceiverClientId" => "49873",
        "ReceiverName" => "YIN, Andy",
        "DonatedToAddress1" => nil,
        "DonatedToAddress2" => nil,
        "DonatedToSuburb" => nil,
        "DonatedToPostCode" => nil,
        "DonatedToState" => nil,
        "GiftDate" => "2025-02-18T00:00:00",
        "GiftValue" => 2400
      }
    end

    it 'has the correct attributes' do
      expect(donation.amount).to eq(2400)
      expect(donation.donor_name).to eq('ACY Securities Pty Ltd')
      expect(donation.recipient_name).to eq('YIN, Andy')
      expect(donation.date).to eq(Date.new(2025, 2, 18))
      expect(donation.donor_aec_id).to eq('51277')
      expect(donation.recipient_aec_id).to eq('49873')
      # expect(donation.financial_year).to eq('2024-25')
      # expect(donation.return_id).to eq('80518')
      expect(donation.donation_type).to eq('federal_election_donation')
      expect(donation.event_id).to eq('31496')
    end
  end
end
