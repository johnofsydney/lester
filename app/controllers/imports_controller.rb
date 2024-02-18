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
    file = params['project']['filename'].tempfile
    csv = CSV.read(file, headers: true)
    csv.each do |row|
      donation_date = Date.new( "20#{row['Financial Year'].last(2)}".to_i, 6, 30) # saves bothering about the date format
      financial_year = Dates::FinancialYear.new(donation_date)

      transfer = Transfer.find_or_create_by(
        giver: Donor::RecordDonation.call(row["Donor Name"]),
        taker: RecordTransferTaker.call(row["Donation Made To"]),
        effective_date: financial_year.last_day, # group all donations for a financial year. There are too many otherwise.
        transfer_type: 'donation',
        evidence: 'https://transparency.aec.gov.au/AnnualDonor',
      )

      transfer.data ||= {}
      transfer.data[:donation_date] = {
        donation_date: {
          giver: Donor::RecordDonation.call(row["Donor Name"]),
          taker: RecordTransferTaker.call(row["Donation Made To"]),
          effective_date: financial_year.last_day, # TODO: use the real donation date
          transfer_type: 'donation',
          evidence: 'https://transparency.aec.gov.au/AnnualDonor',
          amount: row['Amount'].to_i,
        }
      }

      transfer.amount += row['Amount'].to_i
      transfer.save
    end

    redirect_to groups_path
  end

  def infer_date(row)
    begin
      Date.parse(row['Date'])
    rescue => exception
      Date.new( "20#{row['Financial Year'].last(2)}".to_i, 6, 30)
    end
  end
end

