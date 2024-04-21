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
      parliament = RecordGroup.call('Australian Federal Parliament')

      csv = CSV.read(file, headers: true)
      csv.each do |row|
        next if Person.find_by(name: row['name']) # GUARD! IS TOO STRICT!
        print "."

        # Start and End Dates for Person in Parliament
        start_date = parse_date(row['start_date'])
        end_date = parse_date(row['end_date'])

        person = Person.find_or_create_by(name: row['name'].titleize)
        federal_party = RecordGroup.call(row['party'].titleize)
        state_party = RecordGroup.call(
          row['party'].downcase.gsub('federal', row['state'])
        )


        senator = file.match?(/senator/i) ? true : false
        # senator = row['electorate'].match?(/Queensland|New South Wales|Victoria|Tasmania|South Australia|Western Australia|Northern Territory|Australian Capital Territory/i) ? true : false
        independent = federal_party.name.match?(/Independent/)
        major_party = federal_party.name.match?(/ALP|Liberals|Greens|Nationals|One Nation/)

        title = senator ? 'Senator' : 'MP'
        electorate_naming = senator ? 'Senators for' : 'Electorate of'

        # TODO: THIS DOES NOT WORK WELL, ESP SENATORS
        electorate = RecordGroup.call("#{electorate_naming} #{row['electorate']} (#{federal_party.less_level})")


        if Membership.where(member: person, group: parliament).empty?
          parliament_membership = Membership.find_or_create_by(member: person, group: parliament, start_date: start_date, end_date: end_date)
          parliament_membership.save
          Position.create(membership: parliament_membership, title:, start_date: start_date, end_date: end_date)
        end



        # if Membership.where(member: person, group: electorate).empty?
        # end

        next if independent

        if Membership.where(member: person, group: federal_party).empty?
          federal_membership = Membership.find_or_create_by(member: person, group: federal_party)
          federal_membership.save
          Position.create(membership: federal_membership, title: 'Party Member Of Federal Party') unless independent

          if major_party
            state_membership = Membership.find_or_create_by(member: person, group: state_party)
            state_membership.save
            Position.create(membership: state_membership, title: 'Member of State Party')
          end
        end
      end
    end

    def ministries_upload(file)
      csv = CSV.read(file, headers: true)
      csv.each do |row|
        ministry_group = RecordGroup.call(row['group'])
        person = Person.find_by(name: row['person'].titleize) || raise
        title = row['title']
        start_date = parse_date(row['start_date'])
        end_date = parse_date(row['end_date'])


        membership = Membership.find_or_create_by(member: person, group: ministry_group, start_date: start_date, end_date: end_date)

        Position.create(membership: membership, title: title, start_date: start_date, end_date: end_date)
        rescue => e

          p "Error: #{e}"
          binding.pry
      end
    end

    def member_of_parliament_upload(file)
      raise 'hell'
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