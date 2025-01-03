namespace :lester do
  desc "Find Duplicates"
  task find_duplicates: :environment do
    groups = Group.order(:name).pluck(:name).map(&:upcase)
    people = Person.order(:name).pluck(:name).map(&:upcase)

    p people.tally.select { |_, count| count > 1 }.keys
    p groups.tally.select { |_, count| count > 1 }.keys

    p (groups + people).tally.select { |_, count| count > 1 }.keys
  end

  desc "Remove Duplicates"
  task merge_duplicates: :environment do
    ## MERGING EXAMPLE ##
    # ey = Group.find_by(name: 'EY')
    # ernst_and_young = Group.find_by(name: 'Ernst & Young')
    # ey.merge_into(ernst_and_young)

    ralph_party = Group.find_by(name: 'United Australia Federal')
    clive_party = Group.find_by(name: 'United Australia Party')
    print "Merging #{ralph_party.name} into #{clive_party.name}... "
    ralph_party.merge_into(clive_party)
    puts "done."
  end
end