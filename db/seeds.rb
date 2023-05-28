
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
bob_brown = Person.find_or_create_by(name: 'Bob Brown')
allegra_spender = Person.find_or_create_by(name: 'Allegra Spender')
zalie_stegall = Person.find_or_create_by(name: 'Zali Stegall')

paul_wheelton = Person.find_or_create_by(name: 'Paul Wheelton')
scott_farquar = Person.find_or_create_by(name: 'Scott Farquar')
mike_cannon_brookes = Person.find_or_create_by(name: 'Mike Cannon-Brookes')
simon_holmes_acourt = Person.find_or_create_by(name: 'Simon Holmes a Court')

amie_frydenburg = Person.find_or_create_by(name: 'Amie Frydenburg')

federal_government = Group.find_or_create_by(name: 'Australian Federal Government')
wheelton_investments = Group.find_or_create_by(name: 'Wheelton Investments Pty Ltd')
guide_dogs_victoria = Group.find_or_create_by(name: 'Guide Dogs Victoria')
the_coalition = Group.find_or_create_by(name: 'The Coalition')
labor = Group.find_or_create_by(name: 'Labor')
the_greens = Group.find_or_create_by(name: 'The Greens')
atlassian = Group.find_or_create_by(name: 'Atlassian')
climate200 = Group.find_or_create_by(name: 'Climate 200')
teal_independents = Group.find_or_create_by(name: 'Teal Independents')
allegra_spender_campaign = Group.find_or_create_by(name: 'Allegra Spender Campaign')
zalie_stegall_campaign = Group.find_or_create_by(name: 'Zali Stegall Campaign')
frydenburg_family = Group.find_or_create_by(name: 'Frydenburg Family')
lander_and_rogers = Group.find_or_create_by(name: 'Lander and Rogers')


# Membership.create(owner: federal_government, member: the_coalition)
Membership.create(group: the_coalition, person: josh_frydenburg, title: 'Deputy Leader')
Membership.create(group: the_coalition, person: peter_dutton, title: 'Leader')
Membership.create(group: the_coalition, person: scott_morrison, title: 'Leader')
Membership.create(group: labor, person: anthony_albanese, title: 'Leader')
Membership.create(group: labor, person: tanya_plibersek, title: 'Deputy Leader')
Membership.create(group: labor, person: kevin_rudd, title: 'Leader')
Membership.create(group: the_greens, person: bob_brown, title: 'Great Grand Leader')
Membership.create(group: allegra_spender_campaign, person: allegra_spender)
Membership.create(group: zalie_stegall_campaign, person: zalie_stegall)

Membership.create(group: guide_dogs_victoria, person: paul_wheelton, title: 'Capital Campaign Chair')
Membership.create(group: wheelton_investments, person: paul_wheelton, title: 'Owner')
Membership.create(group: climate200, person: simon_holmes_acourt, title: 'Owner')
Membership.create(group: atlassian, person: mike_cannon_brookes, title: 'Owner')
Membership.create(group: atlassian, person: scott_farquar, title: 'Owner')

Membership.create(group: frydenburg_family, person: josh_frydenburg, title: 'Husband')
Membership.create(group: frydenburg_family, person: amie_frydenburg, title: 'Wife')
Membership.create(group: lander_and_rogers, person: amie_frydenburg, title: 'Partner')

Affiliation.create(owning_group: teal_independents, sub_group: allegra_spender_campaign)
Affiliation.create(owning_group: teal_independents, sub_group: zalie_stegall_campaign)
Affiliation.create(owning_group: lander_and_rogers, sub_group: guide_dogs_victoria, title: 'Retained Legal Providers')

Transfer.find_or_create_by(
  giver: federal_government,
  taker: guide_dogs_victoria,
  effective_date: Date.new(2020, 4, 1),
  transfer_type: 'grant',
  amount: 25_000_000
)

Transfer.find_or_create_by(
  giver: paul_wheelton,
  taker: the_coalition,
  effective_date: Date.new(2018, 4, 1),
  transfer_type: 'donation',
  amount: 1500
)

Transfer.find_or_create_by(
  giver: wheelton_investments,
  taker: the_coalition,
  effective_date: Date.new(2019, 4, 1),
  transfer_type: 'donation',
  amount: 1500
)

Transfer.find_or_create_by(
  giver: mike_cannon_brookes,
  taker: climate200,
  effective_date: Date.new(2020, 4, 1),
  transfer_type: 'donation',
  amount: 150000
)

Transfer.find_or_create_by(
  giver: scott_farquar,
  taker: climate200,
  effective_date: Date.new(2020, 4, 1),
  transfer_type: 'donation',
  amount: 150000
)

Transfer.find_or_create_by(
  giver: mike_cannon_brookes,
  taker: allegra_spender_campaign,
  effective_date: Date.new(2020, 4, 1),
  transfer_type: 'donation',
  amount: 150000
)

Transfer.find_or_create_by(
  giver: scott_farquar,
  taker: zalie_stegall_campaign,
  effective_date: Date.new(2020, 4, 1),
  transfer_type: 'donation',
  amount: 150000
)

Transfer.find_or_create_by(
  giver: climate200,
  taker: the_greens,
  effective_date: Date.new(2020, 4, 1),
  transfer_type: 'donation',
  amount: 150000
)

Transfer.find_or_create_by(
  giver: climate200,
  taker: allegra_spender_campaign,
  effective_date: Date.new(2021, 4, 1),
  transfer_type: 'donation',
  amount: 190000
)


Transfer.find_or_create_by(
  giver: guide_dogs_victoria,
  taker: lander_and_rogers,
  effective_date: Date.new(2022, 4, 1),
  transfer_type: 'donation',
  amount: 140000
)




