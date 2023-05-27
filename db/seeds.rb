
Transfer.destroy_all
Membership.destroy_all
Group.destroy_all
Person.destroy_all

# Transaction.destroy_all

josh_frydenburg = Person.find_or_create_by(name: 'Josh Frydenburg')
peter_dutton = Person.find_or_create_by(name: 'Peter Dutton')
scott_morrison = Person.find_or_create_by(name: 'Scott Morrison')
anthony_albanese = Person.find_or_create_by(name: 'Anthony Albanese')
tanya_plibersek = Person.find_or_create_by(name: 'Tanya Plibersek')
kevin_rudd = Person.find_or_create_by(name: 'Kevin Rudd')

paul_wheelton = Person.find_or_create_by(name: 'Paul Wheelton')

federal_government = Group.find_or_create_by(name: 'Australian Federal Government')
wheelton_investments = Group.find_or_create_by(name: 'Wheelton Investments Pty Ltd')
guide_dogs_victoria = Group.find_or_create_by(name: 'Guide Dogs Victoria')
the_coalition = Group.find_or_create_by(name: 'The Coalition')
labor = Group.find_or_create_by(name: 'Labor')


# Membership.create(owner: federal_government, member: the_coalition)
Membership.create(group: the_coalition, person: josh_frydenburg)
Membership.create(group: the_coalition, person: peter_dutton)
Membership.create(group: the_coalition, person: scott_morrison)
Membership.create(group: labor, person: anthony_albanese)
Membership.create(group: labor, person: tanya_plibersek)
Membership.create(group: labor, person: kevin_rudd)

Membership.create(group: guide_dogs_victoria, person: paul_wheelton, title: 'Capital Campaign Chair')
Membership.create(group: wheelton_investments, person: paul_wheelton, title: 'Owner')

# Affiliation.find_or_create_by(owning_group: federal_government, sub_group: the_coalition)
# Affiliation.find_or_create_by(owning_group: federal_government, sub_group: labor)

Transfer.find_or_create_by(
  giver: federal_government,
  taker: guide_dogs_victoria,
  effective_date: Date.new(2020, 4, 1),
  amount: 25_000_000
)

Transfer.find_or_create_by(
  giver: paul_wheelton,
  taker: the_coalition,
  effective_date: Date.new(2018, 4, 1),
  amount: 1500
)

Transfer.find_or_create_by(
  giver: wheelton_investments,
  taker: the_coalition,
  effective_date: Date.new(2019, 4, 1),
  amount: 1500
)


# atlassian = Group.create(name: 'Atlassian')

