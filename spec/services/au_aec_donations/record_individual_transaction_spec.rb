require 'rails_helper'

describe AuAecDonations::RecordIndividualTransaction do
  let(:row_hash) do
    {
      "ViewName" => "Annual Donor Donation Made",
      "RegistrationCode" => "BMQHL5",
      "ReturnId" => 82589,
      "ReturnTypeCode" => "federaldonororganisation",
      "ReturnTypeDescription" => "Organisation Donor Return",
      "FinancialYear" => "2024-25",
      "ClientFileId" => 18051,
      "CurrentClientName" => "Australian Energy Producers",
      "ReturnClientName" => "Australian Energy Producers",
      "DonationMadeToName" => "Australian Labor Party (Western Australian Branch)",
      "DonationMadeToClientFileId" => 53,
      "DonationMadeToClientType" => "politicalparty",
      "TransactionDate" => "2024-07-01T00:00:00",
      "Amount" => 5500,
      "FinancialRecordType" => "donationmade"
    }
  end

  let(:service) { described_class.new(row_hash) }

  it 'creates a donation object' do
    expect(described_class.new(row_hash).donation).to be_an_instance_of(AuAecDonations::Donation)
  end

  it 'creates an IndividualTransaction with the correct attributes' do
    service.call

    individual_transaction = IndividualTransaction.last
    expect(individual_transaction.amount).to eq(5500)
    expect(individual_transaction.effective_date).to eq(Date.new(2024, 7, 1))
    expect(individual_transaction.description).to eq("Donation of $5500.0 from Australian Energy Producers to Australian Labor Party (Western Australian Branch) on 2024-07-01")
    expect(individual_transaction.transaction_type).to eq('Australian Political Donations')
  end

  it 'creates the associated records' do
    service.call

    individual_transaction = IndividualTransaction.last
    expect(individual_transaction.giver.name).to eq("Australian Energy Producers")
    expect(individual_transaction.taker.name).to eq("ALP (WA)")
    expect(individual_transaction.transfer.giver.name).to eq("Australian Energy Producers")
    expect(individual_transaction.transfer.taker.name).to eq("ALP (WA)")
    expect(individual_transaction.transfer.effective_date).to eq(Date.new(2025, 6, 30))
  end

  context 'when there is a subsequent donation to the same recipient, but using a different name' do
    let(:second_donation_row_hash) do
      # NB this will have the same recipient AEC ID as the original row hash
      row_hash.merge(
        "ClientFileId" => 123,
        "CurrentClientName" => "Rich Donor Ltd",
        "DonationMadeToName" => "Perth Office ALP",
        "Amount" => 10000,
        "TransactionDate" => "2024-08-01T00:00:00"
      )
    end

    it 'maps the new recipient name to the same record group' do
      described_class.new(row_hash).call
      described_class.new(second_donation_row_hash).call

      expect(IndividualTransaction.count).to eq(2)
      expect(IndividualTransaction.pluck(:taker_id).uniq.count).to eq(1)
      expect(IndividualTransaction.first.taker.name).to eq("ALP (WA)")
      expect(IndividualTransaction.last.taker.name).to eq("ALP (WA)")
      expect(IndividualTransaction.first.giver.name).to eq("Australian Energy Producers")
      expect(IndividualTransaction.last.giver.name).to eq("Rich Donor Ltd")
    end
  end

  context 'when there is a subsequent donation from the same donor, but using a different name' do
    let(:second_donation_row_hash) do
      # NB this will have the same donor AEC ID as the original row hash
      row_hash.merge(
        "CurrentClientName" => "Rich Donor Ltd",
        "DonationMadeToName" => "Australian Labor Party (Western Australian Branch)",
        "DonationMadeToClientFileId" => 53,
        "Amount" => 10000,
        "TransactionDate" => "2024-08-01T00:00:00"
      )
    end

    it 'maps the new donor name to the same record group' do
      described_class.new(row_hash).call
      described_class.new(second_donation_row_hash).call

      expect(IndividualTransaction.count).to eq(2)
      expect(IndividualTransaction.pluck(:giver_id).uniq.count).to eq(1)
      expect(IndividualTransaction.first.taker.name).to eq("ALP (WA)")
      expect(IndividualTransaction.last.taker.name).to eq("ALP (WA)")
      expect(IndividualTransaction.first.giver.name).to eq("Australian Energy Producers")
      expect(IndividualTransaction.last.giver.name).to eq("Australian Energy Producers")
    end
  end
end