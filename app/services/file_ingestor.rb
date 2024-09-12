class FileIngestor

  class << self
    def annual_donor_ingest(file)
      csv = CSV.read(file, headers: true)
      csv.each do |row|
        donation_date = Date.new( "20#{row['Financial Year'].last(2)}".to_i, 6, 30) # saves bothering about the date format
        financial_year = Dates::FinancialYear.new(donation_date)
        giver = RecordPersonOrGroup.call(row["Donor Name"])
        taker = RecordPersonOrGroup.call(row["Donation Made To"])

        transfer = Transfer.find_or_create_by(
          giver_id: giver.id,
          giver_type: giver.class.name,
          taker_id: taker.id,
          taker_type: taker.class.name,
          effective_date: financial_year.last_day, # group all donations for a financial year. There are too many otherwise.
          transfer_type: 'donations',
          evidence: 'https://transparency.aec.gov.au/AnnualDonor',
        )

        transfer.data ||= {}
        transfer.donations ||= []

        # this is for the JSON data field, recording each individual donation
        transfer.donations << {
          giver: giver.name,
          taker: taker.name,
          effective_date: financial_year.last_day,
          donation_date: row['Date'],
          transfer_type: 'donation',
          evidence: 'https://transparency.aec.gov.au/AnnualDonor',
          amount: row['Amount'].to_i
        }

        transfer.amount += row['Amount'].to_i

        print 'd'
        transfer.save
      end
    end

    def referendum_donor_ingest(file)
      csv = CSV.read(file, headers: true)
      csv.each do |row|
        donation_date = parse_date(row['Date'])
        financial_year = Dates::FinancialYear.new(donation_date)
        giver = RecordPersonOrGroup.call(row["Donor Name"])
        taker = RecordPersonOrGroup.call(row["Donation Made To"])

        transfer = Transfer.find_or_create_by(
          giver_id: giver.id,
          giver_type: giver.class.name,
          taker_id: taker.id,
          taker_type: taker.class.name,
          effective_date: financial_year.last_day, # group all donations for a financial year. There are too many otherwise.
          transfer_type: 'donations',
          evidence: 'https://transparency.aec.gov.au/ReferendumDonor',
        )

        transfer.data ||= {}
        transfer.donations ||= []

        # this is for the JSON data field, recording each individual donation
        transfer.donations << {
          giver: giver.name,
          taker: taker.name,
          effective_date: financial_year.last_day,
          donation_date:,
          transfer_type: 'donation',
          evidence: 'https://transparency.aec.gov.au/ReferendumDonor',
          amount: row['Amount'].to_i
        }

        transfer.amount += row['Amount'].to_i

        print 'd'
        transfer.save
      end
    end

    def federal_parliamentarians_upload(file)
      parliament = RecordGroup.call('Australian Federal Parliament')

      csv = CSV.read(file, headers: true)
      csv.each do |row|
        next if Person.find_by(name: row['name']) # GUARD! IS TOO STRICT!

        person = RecordPerson.call(row['name'])
        print 'p'

        senator = file.match?(/senator/i) ? true : false
        title = senator ? 'Senator' : 'MP'

        # Start and End Dates for Person in Parliament
        start_date = parse_date(row['start_date'])
        end_date = parse_date(row['end_date'])

        if Membership.where(member: person, group: parliament).empty?
          parliament_membership = Membership.find_or_create_by(member: person, group: parliament, start_date: start_date, end_date: end_date)
          # parliament_membership.save
          Position.create(membership: parliament_membership, title:, start_date:, end_date:)
        end

        # this relies on the csv file being cleaned, so that independents have /indepedent/ in the party column
        independent = row['party'].match?(/Independent/)

        # independents are not in a party, so we don't need to create a party membership for them
        # we also don't need to create a branch / electorate membership for them, that's handled independently
        next if independent

        federal_party = RecordGroup.call(row['party'])
        major_party = federal_party.name.match?(/ALP|Liberals|Greens|Nationals/)

        # For MPs who belong to a party, create a membership and position.
        # For major parties, also create a state membership and position
        if Membership.where(member: person, group: federal_party).empty?
          federal_membership = Membership.find_or_create_by(member: person, group: federal_party)
          title = major_party ? 'Federal Parliamentary Party Member' : 'Party Member'

          Position.create(membership: federal_membership, title:)

          # MPs are members of a branch, which is a subgroup of party
          # this is where we can add preselectors who choose the candidates for the electorate
          # for major parties the branch is a subgroup of the state party
          # for minor parties the branch is a subgroup of the federal party
          # add this back later if wanted
          unless senator || true # it is the || true which prevents this from running. remove if needed
            branch_name = "#{federal_party.less_level} Branch for #{row['electorate']} Electorate"
            branch = RecordGroup.call(branch_name)

            branch_membership = Membership.find_or_create_by(member: person, group: branch)
            Position.create(membership: branch_membership, title: 'Candidate', start_date:, end_date:)
          end

          if major_party
            state_party = RecordGroup.call(row['party'].downcase.gsub('federal', row['state']))
            state_membership = Membership.find_or_create_by(member: person, group: state_party)

            Position.create(membership: state_membership, title: "Party Member (#{state_party.state})")

            # affiliate the branch with the state party
            Membership.find_or_create_by(
              member_type: "Group",
              member_id: branch.id,
              group: state_party,
            ) unless senator || true
          else
            # affiliate the branch with the federal party
            Membership.find_or_create_by(
              member_type: "Group",
              member_id: branch.id,
              group: federal_party,
            ) unless senator || true
          end
        end
      end
    end

    def ministries_upload(file)
      csv = CSV.read(file, headers: true)
      csv.each do |row|
        ministry_group = RecordGroup.call(row['group'])

        person = RecordPerson.call(row['person'])
        title = row['title'].strip if row['title']
        start_date = parse_date(row['start_date'])
        end_date = parse_date(row['end_date'])

        # the party membership may not exist, if so, we need to create it
        membership = Membership.find_or_create_by(
          member_type: "Person",
          member_id: person.id,
          group: ministry_group
        )
        # create position for each row, with unique dates and title
        Position.find_or_create_by(membership:, title:, start_date:, end_date:)
        rescue => e

        p "Error: #{e} | row#{row.inspect}"
      end
    end

    def general_upload(file)
      csv = CSV.read(file, headers: true)
      csv.each do |row|
        group = RecordGroup.call(row['group'])

        next unless row['person'].present?

        person = RecordPerson.call(row['person'])

        title = row['title'].strip if row['title'].present?
        evidence = row['evidence'].strip if row['evidence'].present?
        start_date = parse_date(row['start_date']) if row['start_date'].present?
        end_date = parse_date(row['end_date']) if row['end_date'].present?

        # the membership may not exist, if so, we need to create it
        membership = Membership.find_or_create_by(
          member_type: "Person",
          member_id: person.id,
          group: group
        )
        # create position for each row, with unique dates and title
        if (title || start_date || end_date)
          position = Position.find_or_create_by(membership:, title:, start_date:, end_date:)
        end

        membership.update(evidence:) if evidence
        position.update(evidence:) if evidence && position

        rescue => e
        p "General Upload | Error: #{e} | row#{row.inspect}"
      end
    end

    def affiliations_upload(file)
      csv = CSV.read(file, headers: true)
      csv.each do |row|
        owning_group = RecordGroup.call(row['group'])
        member_group = RecordGroup.call(row['member_group'])

        evidence = row['evidence'].strip if row['evidence'].present?

        membership = Membership.find_or_create_by(
          member_type: "Group",
          member_id: member_group.id,
          group: owning_group,
          start_date: parse_date(row['start_date']),
          end_date: parse_date(row['end_date'])
        )

        membership.update(evidence:) if evidence

        print 'm'
      end
    end

    def transfers_upload(file)
      csv = CSV.read(file, headers: true)
      csv.each do |row|
        giver = RecordPersonOrGroup.call(row["giver"])
        taker = RecordPersonOrGroup.call(row["taker"])

        transfer = Transfer.find_or_create_by(
          giver: giver,
          taker: taker,
          effective_date: parse_date(row['effective_date']),
          transfer_type: row['transfer_type'],
          amount: row['amount'],
          evidence: row['evidence']
        )

        print 't'
      end
    end

    def member_of_parliament_upload(file)
      raise 'hell'
    end

    def parse_date(date)
      return nil unless date.present?

      begin
        Date.parse(date)
      rescue => exception
        nil
      end
    end
  end
end