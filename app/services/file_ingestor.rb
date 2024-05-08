class FileIngestor

  class << self
    def annual_donor_ingest(file)
      csv = CSV.read(file, headers: true)
      csv.each do |row|
        donation_date = Date.new( "20#{row['Financial Year'].last(2)}".to_i, 6, 30) # saves bothering about the date format
        financial_year = Dates::FinancialYear.new(donation_date)

        transfer = Transfer.find_or_create_by(
          giver: RecordDonation.call(row["Donor Name"]),
          taker: RecordGroup.call(row["Donation Made To"]),
          effective_date: financial_year.last_day, # group all donations for a financial year. There are too many otherwise.
          transfer_type: 'donations',
          evidence: 'https://transparency.aec.gov.au/AnnualDonor',
        )

        transfer.data ||= {}
        transfer.donations ||= []

        transfer.donations << {
          giver: RecordDonation.call(row["Donor Name"])&.name,
          taker: RecordGroup.call(row["Donation Made To"])&.name,
          effective_date: financial_year.last_day,
          donation_date: row['Date'],
          transfer_type: 'donation',
          evidence: 'https://transparency.aec.gov.au/AnnualDonor',
          amount: row['Amount'].to_i
        }

        transfer.amount += row['Amount'].to_i

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

        person = RecordPerson.call(row['name'])

        # TODO: indeoendent do not have party!
        federal_party = RecordGroup.call(row['party'])
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
          next if independent
          federal_membership = Membership.find_or_create_by(member: person, group: federal_party)
          federal_membership.save
          title = major_party ? 'Party Member (Federal)' : 'Party Member'
          Position.create(membership: federal_membership, title:)

          if major_party
            state_membership = Membership.find_or_create_by(member: person, group: state_party)
            state_membership.save
            Position.create(
              membership: state_membership,
              title: "Party Member (#{state_party.state})"
            )
          end
        end
      end
    end

    def ministries_upload(file)
      csv = CSV.read(file, headers: true)
      csv.each do |row|
        ministry_group = RecordGroup.call(row['group'])

        person = RecordPerson.call(row['person'])
        title = row['title']
        start_date = parse_date(row['start_date'])
        end_date = parse_date(row['end_date'])

        # the party membership may not exist, if so, we need to create it
        membership = Membership.find_or_create_by(
          member_type: "Person",
          member_id: person.id,
          group: ministry_group
        )
        # create position for each row, with unique dates and title
        Position.find_or_create_by(membership: membership, title: title, start_date: start_date, end_date: end_date)
        rescue => e

          p "Error: #{e}"
      end
    end

    def general_upload(file)
      csv = CSV.read(file, headers: true)
      csv.each do |row|
        print "-"
        group = RecordGroup.call(row['group'])
        person = RecordPerson.call(row['person'])

        title = row['title']
        start_date = parse_date(row['start_date'])
        end_date = parse_date(row['end_date'])

        # the membership may not exist, if so, we need to create it
        membership = Membership.find_or_create_by(
          member_type: "Person",
          member_id: person.id,
          group: group
        )
        # create position for each row, with unique dates and title
        if (title || start_date || end_date)
          Position.find_or_create_by(membership:, title:, start_date:, end_date:)
        end
        rescue => e

          p "Error: #{e}"
      end
    end

    def affiliations_upload(file)
      csv = CSV.read(file, headers: true)
      csv.each do |row|
        print ":"
        owning_group = RecordGroup.call(row['group'])
        member_group = RecordGroup.call(row['member_group'])

        membership = Membership.find_or_create_by(
          member_type: "Group",
          member_id: member_group.id,
          group: owning_group,
          start_date: parse_date(row['start_date']),
          end_date: parse_date(row['end_date'])
        )
      end
    end

    def transfers_upload(file)
      csv = CSV.read(file, headers: true)
      csv.each do |row|
        print "+"
        giver = RecordGroup.call(row['giver'])
        taker = RecordGroup.call(row['taker'])

        transfer = Transfer.find_or_create_by(
          giver: giver,
          taker: taker,
          effective_date: parse_date(row['effective_date']),
          transfer_type: row['transfer_type'],
          amount: row['amount'],
          evidence: row['evidence']
        )
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