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
      date = row['Date'].present? ? Date.parse(row['Date']) : Date.new(2022,6,30)
      giver = Donor::RecordDonation.call(row["Donor Name"])
      taker = Party::RecordDonation.call(row["Donation Made To"])
      amount = row["Amount"].to_i

      Transaction.create(
        giver_type: giver.class.to_s,
        taker: taker,
        giver: giver,
        date: date,
        amount: amount
      )
    end

    redirect_to groups_path
  end
end