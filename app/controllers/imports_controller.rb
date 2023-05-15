require 'csv'

class ImportsController < ApplicationController
  layout -> { ApplicationLayout }

  def annual_associated_entity
    render Imports::AnnualAssociatedEntityView.new
  end

  def annual_associated_entity_upload


    lines = File.readlines(params['project']['filename'].tempfile)
                .map(&:strip)
                .map{|l| l.split(',') }

    headings = lines.shift.map(&:downcase).map(&:to_sym)

    data = []
    lines.each do |line|
      data << headings.zip(line).to_h
    end


    row = data.first.transform_keys(&:to_s).transform_keys{|k| k.gsub(' ','_')}.transform_keys(&:to_sym)
    date = Date.new( "20#{row[:financial_year].last(2)}".to_i, 6, 30)
    donor = Group.find_or_create_by(name: row[:name])
    party = Group.find_or_create_by(name: row[:associated_political_parties_or_disclosure_entities])
    donation = row[:total_payments].to_i


    binding.pry

    # render CsvSorter::UploadView.new(headings:, data:)
  end

  def annual_donor
    render Imports::AnnualDonorView.new
  end

  def annual_donor_upload

    file = params['project']['filename'].tempfile
    csv = CSV.read(file, headers: true)
    csv.each do |row|
      # binding.pry
      if row['Date'].present?
        date = Date.parse(row['Date'])
      else
        date = Date.new(2022,6,30)
      end

      donor = Donor::RecordDonation.call(row["Donor Name"])
      party = Party::RecordDonation.call(row["Donation Made To"])
      amount = row["Amount"].to_i

      donation = Donation.create(
        donor_type: donor.class.to_s,
        donee: party,
        donor: donor,
        date: date,
        amount: amount
      )



      puts donation
      puts date
      puts donor.name
      puts party.name

    end

    redirect_to groups_path
  end
end