namespace :lester do
  # desc 'Find Duplicates'
  # task find_duplicates: :environment do
  #   groups = Group.order(:name).pluck(:name).map(&:upcase)
  #   people = Person.order(:name).pluck(:name).map(&:upcase)

  #   p people.tally.select { |_, count| count > 1 }.keys
  #   p groups.tally.select { |_, count| count > 1 }.keys

  #   p (groups + people).tally.select { |_, count| count > 1 }.keys
  # end

  desc 'Find Duplicates'
  task find_duplicates: :environment do
    group_duplicates = Groups::DeleteDuplicates.new.duplicates
    person_duplicates = People::DeleteDuplicates.new.duplicates

    p "People duplicates (name => [ids]):", person_duplicates
    p "Group duplicates (name => [ids]):", group_duplicates
  end

  desc 'Potential People in the Groups Table'
  task potential_people: :environment do
    potential_people = Group.order(:name).pluck(:name).filter do |name|
      service = RecordPersonOrGroup.new(name)
      service.person_or_group == 'person'
    end

    p potential_people
  end

  desc 'Create a group for all sole trader lobbyists'
  task create_sole_trader_groups: :environment do
    lobbyist_people = Group.find_by(name: 'Lobbyists').people
    sole_traders  = lobbyist_people.select{|person| person.memberships.count == 1 }

    sole_traders.each do |person|
      group = RecordGroup.call("#{person.name} Lobbying")
      p "Created group: #{group.name}"

      membership = Membership.create(group: group, member: person, member_type: 'Person')
      Position.create(membership: membership, title: 'Sole Trader')
    end
  end

  desc 'Clear Cache for Network Graph and Count'
  task clear_cache: :environment do
    Group.update_all(cached_data: {})
    Person.update_all(cached_data: {})

  end

  desc 'Back Fill all the Aus Tender Contracts going back to 2018-01-01'
  # This task can be deleted when completed
  task backfill_contracts: :environment do
    start_date = Date.new(2018, 1, 1)

    backfill = ContractBackfill.first_or_create!(last_processed_date: start_date)

    puts "Backfill starting at #{backfill.last_processed_date}"

    BackfillContractsMasterJob.perform_async(backfill.last_processed_date.to_s)
  end
end