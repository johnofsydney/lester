namespace :lester do
  desc "Find Duplicates"
  task find_duplicates: :environment do
    groups = Group.order(:name).pluck(:name).map(&:upcase)
    people = Person.order(:name).pluck(:name).map(&:upcase)

    p people.tally.select { |_, count| count > 1 }.keys
    p groups.tally.select { |_, count| count > 1 }.keys

    p (groups + people).tally.select { |_, count| count > 1 }.keys
  end

  desc 'Potential People in the Groups Table'
  task potential_people: :environment do
    potential_people = Group.order(:name).pluck(:name).filter do |name|
      service = RecordPersonOrGroup.new(name)
      service.person_or_group == 'person'
    end

    p potential_people
  end

  desc "Remove Duplicates"
  task merge_duplicates: :environment do
    ## MERGING EXAMPLE ##
    # ey = Group.find_by(name: 'EY')
    # ernst_and_young = Group.find_by(name: 'Ernst & Young')
    # ey.merge_into(ernst_and_young)

    # # CMAX and Clubs NSW already fixed in map_group_names.rb
    # low_cmax = Group.find_by(name: 'Cmax Advisory')
    # caps_cmax = Group.find_by(name: 'CMAX Advisory')
    # p "Merging #{low_cmax.name} into #{caps_cmax.name}... "
    # low_cmax.merge_into(caps_cmax)

    # low_clubs = Group.find_by(name: 'Registered Clubs Association of NSW (t/as Clubsnsw)')
    # caps_clubs = Group.find_by(name: 'Registered Clubs Association of NSW (T/As ClubsNSW)')
    # p "Merging #{low_clubs.name} into #{caps_clubs.name}... "
    # low_clubs.merge_into(caps_clubs)

    # # was created as group with person name and with lobbying suffix
    # jannette_group = Group.find_by(name: 'Jannette Cotterell')
    # jannette_lobbying = Group.find_by(name: 'Jannette Cotterell Lobbying')
    # p "Merging #{jannette_group.name} into #{jannette_lobbying.name}... "
    # jannette_group.merge_into(jannette_lobbying)

    # # is duplicated in the lobbyists category. fixed memberhip to validate for duplicates
    # lobbyist_category = Group.find_by(name: 'Lobbyists')
    # memberships = Membership.where(group: lobbyist_category, member: jannette_lobbying)
    # if memberships.count > 1
    #   memberships.last.destroy
    #   p "Deleted duplicate membership for #{jannette_lobbying.name}"
    # end
    idameno_123_abn = Group.find_by(name: 'Idameneo (No 123) Pty Ltd')
    idameno_123_dot = Group.find_by(name: 'Idameneo (No. 123) Pty Ltd')
    idameno_123_abn.other_names << 'The Artlu Unit Trust'
    idameno_123_abn.save
    idameno_123_dot.merge_into(idameno_123_abn)

    smart_short = Group.find_by(name: 'Smart Energy Council')
    smart_long = Group.find_by(name: 'Smart Energy Council (previously Australian Solar Council)')
    smart_long.merge_into(smart_short)
    smart_short.other_names << 'Australian Solar Council'
    smart_short.save

    union_short = Group.find_by(name: 'The Union Education Foundation')
    union_long = Group.find_by(name: 'The Union Education Foundation Limited')
    union_long.merge_into(union_short)

    p "done."
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

  desc 'CLear Cache for Network Graph and Count'
  task clear_cache: :environment do
    Group.all.update_all(cached_data: {})
    Person.all.update_all(cached_data: {})

  end
end