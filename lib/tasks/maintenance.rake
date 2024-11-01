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
  task remove_duplicates: :environment do
    ## MERGING EXAMPLE ##
    # ey = Group.find_by(name: 'EY')
    # ernst_and_young = Group.find_by(name: 'Ernst & Young')
    # ey.merge_into(ernst_and_young)
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
      end #.sole.update(start_date: m.start_date, end_date: m.end_date)
      # puts 'm'
    end
  end
end