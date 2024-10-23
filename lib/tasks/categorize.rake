namespace :lester do
  desc "Categorize"
  task categorize: :environment do

    # ['Gambling', 'Digging & Drilling', 'Consulting', 'Pharmaceuticals', 'Retail', 'Energy', 'Insurance'].each do |category|
    #   Group.create(name: category, category: true)
    # end

    # Create the category groups
    digging_drilling = RecordGroup.call('Digging & Drilling', category: true)
    gambling = RecordGroup.call('Gambling', category: true)
    consulting = RecordGroup.call('Consulting', category: true)
    pharmaceuticals = RecordGroup.call('Pharmaceuticals', category: true)
    retail = RecordGroup.call('Retail', category: true)
    energy = RecordGroup.call('Energy', category: true)
    insurance = RecordGroup.call('Insurance', category: true)
    labour_hire = RecordGroup.call('Labour Hire', category: true)
    banking = RecordGroup.call('Banking', category: true)

    coalition = RecordGroup.call('Coalition', category: true)
    labor = RecordGroup.call('Labor', category: true)
    greens = RecordGroup.call('Greens', category: true)

    # Diggin and Drilling
    # Minerals Council of Australia
    minerals_council = Group.find_by(name: 'Minerals Council of Australia')
    Membership.create(member: minerals_council, group: digging_drilling)
    minerals_council.groups.each do |group|
      Membership.create(member: group, group: digging_drilling)
    end
    gas_energy_australia = Group.find_by(name: 'Gas Energy Australia')
    Membership.create(member: gas_energy_australia, group: digging_drilling)
    gas_energy_australia.groups.each do |group|
      Membership.create(member: group, group: digging_drilling)
    end
    ['Santos Limited'].each do |company|
      Membership.create(member: Group.find_by(name: company), group: digging_drilling)
    end

    # Gambling
    ['Sportsbet Pty Ltd', 'Tabcorp Holdings Limited', 'Beteasy Pty Ltd', 'The Star Entertainment Group Limited', 'Crown Resorts Limited', 'Flutter Entertainment'].each do |company|
      Membership.create(member: Group.find_by(name: company), group: gambling)
    end

    # Consulting
    ['KPMG Australia', 'PricewaterhouseCoopers', 'Deloitte Touche Tohmatsu', 'Ernst & Young', 'Mckinsey & Company'].each do |company|
      Membership.create(member: Group.find_by(name: company), group: consulting)
    end

    # Pharmaceuticals
    ['Novartis Pharmaceuticals Australia Pty Ltd', 'Organon Pharma Pty Ltd', 'Pfizer Australia Pty Ltd', 'The Pharmacy Guild of Australia'].each do |company|
      Membership.create(member: Group.find_by(name: company), group: pharmaceuticals)
    end

    # Energy
    australian_energy_producers = Group.find_by(name: 'Australian Energy Producers')
    australian_energy_producers.groups.each do |group|
      Membership.create(member: group, group: energy)
    end
    gas_energy_australia.groups.each do |group|
      Membership.create(member: group, group: energy)
    end

    # Labour Hire
    ['Programmed Skilled Workforce Limited'].each do |company|
      Membership.create(member: Group.find_by(name: company), group: labour_hire)
    end

    # Banking
    Group.where('name LIKE ?', "%Bank%").each do |group|
      Membership.create(member: group, group: banking)
    end

    # Insurance
    Group.where('name LIKE ?', "%Insurance%").each do |group|
      Membership.create(member: group, group: insurance)
    end




    # Coalition
    Group.where('name LIKE ?', "%Nationals%").each do |group|
      Membership.create(member: group, group: coalition)
    end
    Group.where('name LIKE ?', "%Liberals%").each do |group|
      Membership.create(member: group, group: coalition)
    end
    Group.where('name LIKE ?', "%Liberal National%").each do |group|
      Membership.create(member: group, group: coalition)
    end

    # Labor
    Group.where('name LIKE ?', "%ALP%").each do |group|
      Membership.create(member: group, group: labor)
    end

    # Greens
    Group.where('name LIKE ?', "%Greens%").each do |group|
      Membership.create(member: group, group: greens)
    end


  end
end
