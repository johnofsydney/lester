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
        next if Person.find_by(name: row['name'])

        person = Person.find_or_create_by(name: row['name'].titleize)

        party = RecordGroup.call(row['party'].titleize)
        start_date = parse_date(row['start_date'])
        end_date = parse_date(row['end_date'])

        # membership of a party
        if Membership.where(member: person, group: party).empty?
          print "."
          membership = Membership.find_or_create_by(member: person, group: party)
          membership.save
          Position.create(membership: membership, title: 'Party Member 1')

          # membership of a party for a state
          print "."
          state_party = RecordGroup.call(row['party'].titleize + ' ' + row['state'].upcase)

          state_membership = Membership.find_or_create_by(member: person, group: state_party)
          state_membership.save
          Position.create(membership: state_membership, title: 'Party Member 2  ')

          # membership of the parliament
          print "."
          parliament = RecordGroup.call('Australian Federal Parliament')
          parliament_membership = Membership.find_or_create_by(member: person, group: parliament, start_date: start_date, end_date: end_date)
          Position.create(membership: parliament_membership, title: 'Member of Parliament', start_date: start_date, end_date: end_date)
        end

        # membership of a party ofr their state
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