require 'csv'

class ImportsController < ApplicationController
  layout -> { ApplicationLayout }

  def annual_associated_entity
    render Imports::AnnualAssociatedEntityView.new
  end

  def annual_donor
    render Imports::AnnualDonorView.new
  end

  def annual_donor_upload
    # TODO: make this a find or create
    file = params['project']['filename'].tempfile
    csv = CSV.read(file, headers: true)
    csv.each do |row|
      donation_date = row['Date'].present? ? Date.parse(row['Date']) : Date.new( "20#{row['Financial Year'].last(2)}".to_i, 6, 30)
      financial_year = Dates::FinancialYear.new(donation_date)

      transfer = Transfer.find_or_create_by(
        giver: Donor::RecordDonation.call(row["Donor Name"]),
        taker: Party::RecordDonation.call(row["Donation Made To"]),
        effective_date: financial_year.last_day,
        transfer_type: 'donation',
        evidence: 'https://transparency.aec.gov.au/AnnualPoliticalParty',
      )

      transfer.amount += row['Amount'].to_i
      transfer.save
    end

    redirect_to groups_path
  end
end