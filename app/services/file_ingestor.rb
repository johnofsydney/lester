class FileIngestor

  class << self
    def annual_donor_ingest(file)
      csv = CSV.read(file, headers: true)
      csv.each do |row|
        donation_date = Date.new( "20#{row['Financial Year'].last(2)}".to_i, 6, 30) # saves bothering about the date format
        financial_year = Dates::FinancialYear.new(donation_date)

        transfer = Transfer.find_or_create_by(
          giver: Donor::RecordDonation.call(row["Donor Name"]),
          taker: RecordGroup.call(row["Donation Made To"]),
          effective_date: financial_year.last_day, # group all donations for a financial year. There are too many otherwise.
          transfer_type: 'donations',
          evidence: 'https://transparency.aec.gov.au/AnnualDonor',
        )

        transfer.data ||= {}
        transfer.donations ||= []

        transfer.donations << {
          giver: Donor::RecordDonation.call(row["Donor Name"])&.name,
          taker: RecordGroup.call(row["Donation Made To"])&.name,
          effective_date: financial_year.last_day,
          donation_date: row['Date'],
          transfer_type: 'donation',
          evidence: 'https://transparency.aec.gov.au/AnnualDonor',
          amount: row['Amount'].to_i
        }

        transfer.amount += row['Amount'].to_i

        # p "#{file} || Transfer: #{transfer.inspect}"
        p "Donations: #{transfer.donations.inspect}"
        transfer.save
      end
    end

    def federal_parliamentarians_upload(file)
      csv = CSV.read(file, headers: true)
      csv.each do |row|
        first_elected = parse_date(row['Elected'])
        person = Person.find_or_create_by(name: row['Member'].titleize)
        party = RecordGroup.call(row['Party'].titleize)

        # create (or find) a membership for each person in their party
        membership_party = Membership.find_or_create_by(member: person, group: party)
        membership_party.start_date = first_elected
        membership_party.save
      end
    end

    def parse_date(date)
      begin
        Date.parse(date)
      rescue => exception
        nil
      end
    end
  end
end