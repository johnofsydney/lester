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

    def election_donations_ingest(file)
      csv = CSV.read(file, headers: true)
      csv.each do |row|
        next if row["Donation Made To"].match?(/unendorsed/i)

        donation_date = parse_date(row['Date'])
        financial_year = Dates::FinancialYear.new(donation_date)
        giver = RecordPersonOrGroup.call(row["Name"])
        taker = RecordPersonOrGroup.call(row["Donation Made To"])

        transfer = Transfer.find_or_create_by(
          giver_id: giver.id,
          giver_type: giver.class.name,
          taker_id: taker.id,
          taker_type: taker.class.name,
          effective_date: financial_year.last_day, # group all donations for a financial year. There are too many otherwise.
          transfer_type: 'donations',
          evidence: 'https://transparency.aec.gov.au/Donor',
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
          evidence: 'https://transparency.aec.gov.au/Donor',
          amount: row['Value'].to_i
        }

        transfer.amount += row['Value'].to_i

        print 'd'
        transfer.save
      end
    end

    def nsw_parliamentarians_upload(file)
      parliament = RecordGroup.call('NSW Parliament')

      csv = CSV.read(file, headers: true)
      csv.each do |row|
        person = RecordPerson.call(row['name'])
        print 'p'

        if Membership.where(member: person, group: parliament).empty?
          parliament_membership = Membership.find_or_create_by(member: person, group: parliament)
          parliament_membership.save
          title = row['ministry'].present? ? row['ministry'] : 'NSW MP / MLC'
          Position.create(membership: parliament_membership, title:)
        end

        # this relies on the csv file being cleaned, so that independents have /indepedent/ in the party column
        if row['party'].nil? || row['party'].match?(/independent/i)
          independent = true
        end

        # independents are not in a party, so we don't need to create a party membership for them
        # we also don't need to create a branch / electorate membership for them, that's handled independently
        next if independent

        party = RecordGroup.call(row['party'])
        # major_party = party.name.match?(/ALP|Liberals|Greens|Nationals/)

        # For MPs who belong to a party, create a membership and position.
        if Membership.where(member: person, group: party).empty?
          state_membership = Membership.find_or_create_by(member: person, group: party)
          title = 'Party Member (NSW)'
          Position.create(membership: state_membership, title:)
        end
      end
    end

    def federal_parliamentarians_upload(file)
      parliament = RecordGroup.call('Australian Federal Parliament')

      csv = CSV.read(file, headers: true)
      csv.each do |row|
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

          if major_party
            'Federal Parliamentary Party Member'
            # start / end date - for when they a member of the federal parliamentary party (as opposed to any other branch they might also be in)
            Position.create(membership: federal_membership, title:, start_date:, end_date:)
          else
            title = 'Party Member'
            # no start / end date - we dont know when they became a member of this minor party
            Position.create(membership: federal_membership, title:)
          end

          # MPs are members of a branch, which is a subgroup of party
          # this is where we can add preselectors who choose the candidates for the electorate
          # for major parties the branch is a subgroup of the state party
          # for minor parties the branch is a subgroup of the federal party
          # add this back later if wanted

          # Local Branch membership ==> too hard basket
          # unless senator || true # it is the || true which prevents this from running. remove if needed
          #   branch_name = "#{federal_party.less_level} Branch for #{row['electorate']} Electorate"
          #   branch = RecordGroup.call(branch_name)

          #   branch_membership = Membership.find_or_create_by(member: person, group: branch)
          #   Position.create(membership: branch_membership, title: 'Candidate', start_date:, end_date:)
          # end

          if major_party
            # if the person belongs to a _major_ party, they also belong to the state party too
            state_party = RecordGroup.call(row['party'].downcase.gsub('federal', row['state']))
            state_membership = Membership.find_or_create_by(member: person, group: state_party)

            # dont need start and end date because we dont know when they joined the local state party.
            Position.create(membership: state_membership, title: "Party Member (#{state_party.state})")

          # Local Branch membership ==> too hard basket
          #   # affiliate the branch with the state party
          #   Membership.find_or_create_by(
          #     member_type: "Group",
          #     member_id: branch.id,
          #     group: state_party,
          #   ) unless senator || true
          # else
          #   # affiliate the branch with the federal party
          #   Membership.find_or_create_by(
          #     member_type: "Group",
          #     member_id: branch.id,
          #     group: federal_party,
          #   ) unless senator || true
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

        title = if row['title'].present?
          CapitalizeNames.capitalize(row['title'].strip)
                         .gsub(/\bCEO\b/i) { |word| word.upcase }
        end

        evidence = row['evidence'].strip if row['evidence'].present?
        start_date = parse_date(row['start_date']) if row['start_date'].present?
        end_date = parse_date(row['end_date']) if row['end_date'].present?

        # the membership may not exist, if so, we need to create it
        # There is no start date or end date added to the membership at this point
        membership = Membership.find_or_create_by(
          member_type: "Person",
          member_id: person.id,
          group: group
        )
        # create position for each row, with unique dates and title
        if (title || start_date || end_date)
          position = Position.find_or_create_by(membership:, title:, start_date:, end_date:)
        end

        membership.update!(evidence:) if evidence
        position.update!(evidence:) if evidence && position

        rescue => e
        p "General Upload | Error: #{e} | row#{row.inspect}"
      end
    end

    def lobbyists_upload(file)
      lobbyists = Group.find_or_create_by(name: 'Lobbyists', category: true)

      csv = CSV.read(file, headers: true)
      csv.each do |row|

        person = RecordPerson.call(row['person'])


        evidence = 'https://lobbyists.ag.gov.au/register'

        # Create a membership for the named person and group inthe lobbyists category
        membership = Membership.find_or_create_by(
          member: person,
          group: lobbyists,
          evidence: evidence
        )

        group = RecordGroup.call(row['company']) if row['company'].present?
        title = if row['title'].present?
          CapitalizeNames.capitalize(row['title'].strip)
                         .gsub(/\bCEO\b/i) { |word| word.titleize }
        end

        next if group.nil?
        # Create a membership for the named person in the named group
        # the membership may not exist, if so, we need to create it
        membership = Membership.find_or_create_by(
          member: person,
          group: group
        )
        # create position for each row, with unique dates and title
        position = Position.find_or_create_by(membership:, title:)

        membership.update!(evidence:)
        position.update!(evidence:)

        print "m"


        membership = Membership.find_or_create_by(
          member: group,
          group: lobbyists,
          evidence: evidence
        )

        print "l"

        rescue => e
        p "Lobbyist Upload | Error: #{e} | row#{row.inspect}"
      end
    end

    def affiliations_upload(file)
      client_category = Group.find_or_create_by(name: 'Client of Lobbyists', category: true)

      csv = CSV.read(file, headers: true)
      csv.each do |row|
        owning_group = RecordGroup.call(row['group'])
        member_group = RecordGroup.call(row['member_group'])

        next unless owning_group && member_group
        owning_group.update(business_number: row['business_number'].gsub(/\D/, '')) if row['business_number'].present?
        member_group.update(business_number: row['abn'].gsub(/\D/, '')) if row['abn'].present?

        evidence = row['evidence'].strip if row['evidence'].present?

        membership = Membership.find_or_create_by(
          member_type: "Group",
          member_id: member_group.id,
          group: owning_group,
          start_date: parse_date(row['start_date']),
          end_date: parse_date(row['end_date'])
        )

        membership.update(evidence:) if evidence

        # # ONE TIME ONLY - FOR LOBBYISTS AND CLIENTS
        # Membership.find_or_create_by(
        #   member_type: "Group",
        #   member_id: member_group.id,
        #   group: client_category,
        # )

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