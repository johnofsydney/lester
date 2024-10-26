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
    #  NIOA family
    upper_family = Group.find 1165
    upper_family.destroy

    # NIOA Group
    duplicated_people_nioa_group = [
      Person.find_by(name: 'Hon. Ellen Lord'),
      Person.find_by(name: '. Ken Anderson'),
      Person.find_by(name: 'Hon. David Feeney'),
      Person.find_by(name: 'Hon. Christopher Pyne'),
    ]
    duplicated_people_nioa_group.each do |person|
      person.destroy
    end
    upper_group = Group.find 1164
    upper_group.destroy

    # EY => Ernst & Young
    ey = Group.find_by(name: 'EY')
    ernst_and_young = Group.find_by(name: 'Ernst & Young')
    ey.merge_into(ernst_and_young)
  end
end