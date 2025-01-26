namespace :lester do
  desc "Find Duplicates"
  task find_duplicates: :environment do
    def is_duplicate(group) = Group.all.map(&:name).map(&:upcase).select{|name| name == group.name.upcase }.count > 1

    Group.all.each do |group|
      if is_duplicate(group)
        puts "Duplicate: #{group.name}"
      end
    end
  end

  desc "Remove Duplicates"
  task merge_duplicates: :environment do
    ## MERGING EXAMPLE ##
    # ey = Group.find_by(name: 'EY')
    # ernst_and_young = Group.find_by(name: 'Ernst & Young')
    # ey.merge_into(ernst_and_young)

    # CMAX and Clubs NSW already fixed in map_group_names.rb
    low_cmax = Group.find_by(name: 'Cmax Advisory')
    caps_cmax = Group.find_by(name: 'CMAX Advisory')
    p "Merging #{low_cmax.name} into #{caps_cmax.name}... "
    low_cmax.merge_into(caps_cmax)

    low_clubs = Group.find_by(name: 'Registered Clubs Association of NSW (t/as Clubsnsw)')
    caps_clubs = Group.find_by(name: 'Registered Clubs Association of NSW (T/As ClubsNSW)')
    p "Merging #{low_clubs.name} into #{caps_clubs.name}... "
    low_clubs.merge_into(caps_clubs)

    # was created as group with person name and with lobbying suffix
    jannette_group = Group.find_by(name: 'Jannette Cotterell')
    jannette_lobbying = Group.find_by(name: 'Jannette Cotterell Lobbying')
    p "Merging #{jannette_group.name} into #{jannette_lobbying.name}... "
    jannette_group.merge_into(jannette_lobbying)

    # is duplicated in the lobbyists category. fixed memberhip to validate for duplicates
    lobbyist_category = Group.find_by(name: 'Lobbyists')
    memberships = Membership.where(group: lobbyist_category, member: jannette_lobbying)
    if memberships.count > 1
      memberships.last.destroy
      p "Deleted duplicate membership for #{jannette_lobbying.name}"
    end

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

  desc "Add time range for party memberships"
  task add_time_range_for_party_memberships: :environment do
    positions = Position.where(title: ['MP', 'Senator']) # MP in the Parliament of Australia.

    positions.each do |position|
      m = position.membership

      next unless m.start_date.present? || m.end_date.present?
      next unless m.member_type == 'Person'

      person = Person.find(m.member_id)
      person.positions.where(title: 'Federal Parliamentary Party Member').each do |p|
        if Position.where(membership_id: p.membership_id, title: 'Federal Parliamentary Party Member').count > 1
          raise "Multiple positions for #{person.name}"
        else
          print "#{person.name}, "
          p.update(start_date: m.start_date, end_date: m.end_date)
        end
      end
    end
  end
end