
# Transfer.destroy_all
# Membership.destroy_all
# Group.destroy_all
# Person.destroy_all

# Transaction.destroy_all

josh_frydenburg = Person.find_or_create_by(name: 'Josh Frydenburg')
peter_dutton = Person.find_or_create_by(name: 'Peter Dutton')
scott_morrison = Person.find_or_create_by(name: 'Scott Morrison')
trent_twomey = Person.find_or_create_by(name: 'Trent Twomey')
warren_entsch = Person.find_or_create_by(name: 'Warren Entsch')
junior_entsch = Person.find_or_create_by(name: 'Junior Entsch')
leo_maltam = Person.find_or_create_by(name: 'Leo Maltam')
arthur_sinodinos = Person.find_or_create_by(name: 'Arthur Sinodinos')

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
georgina_twomey = Person.find_or_create_by(name: 'Georgina Twomey')

sally_zou = Person.find_or_create_by(name: 'Sally Zou')

peter_lowy = Person.find_or_create_by(name: 'Peter Lowy')
steven_lowy = Person.find_or_create_by(name: 'Steven Lowy')
david_lowy = Person.find_or_create_by(name: 'David Lowy')
sandro_cirianni = Person.find_or_create_by(name: 'Sandro Cirianni')
karen_hayes = Person.find_or_create_by(name: 'Karen Hayes')
iain_edwards = Person.find_or_create_by(name: 'Iain Edwards')

eddie_obeid =  Person.find_or_create_by(name: 'Eddie Obeid')
moses_obeid =  Person.find_or_create_by(name: 'Moses Obeid')

federal_government = Group.find_or_create_by(name: 'Australian Federal Government')
wheelton_investments = Group.find_or_create_by(name: 'Wheelton Investments Pty Ltd')
guide_dogs_victoria = Group.find_or_create_by(name: 'Guide Dogs Victoria')
the_coalition = Group.find_or_create_by(name: 'The Coalition')
labor = Group.find_or_create_by(name: 'Australian Labor Party')
the_greens = Group.find_or_create_by(name: 'The Greens')
atlassian = Group.find_or_create_by(name: 'Atlassian')
climate200 = Group.find_or_create_by(name: 'Climate 200')
teal_independents = Group.find_or_create_by(name: 'Teal Independents')
allegra_spender_campaign = Group.find_or_create_by(name: 'Allegra Spender Campaign')
zalie_stegall_campaign = Group.find_or_create_by(name: 'Zali Stegall Campaign')
frydenburg_family = Group.find_or_create_by(name: 'Frydenburg Family')
lander_and_rogers = Group.find_or_create_by(name: 'Lander and Rogers')
the_pharmacy_guild = Group.find_or_create_by(name: 'The Pharmacy Guild Of Australia')
warren_entsch_campaign = Group.find_or_create_by(name: 'Warren Entsch Campaign')
qrx_group = Group.find_or_create_by(name: 'QRX Group 1')
twomey_family = Group.find_or_create_by(name: 'Twomey Family')
entsch_family = Group.find_or_create_by(name: 'Entsch Family')
australian_romance = Group.find_or_create_by(name: 'Australian Romance Pty Ltd')
aus_gold_mining = Group.find_or_create_by(name: 'AusGold Mining')
oryxium = Group.find_or_create_by(name: 'Oryxium Investments Limited')
adani = Group.find_or_create_by(name: 'Adani Mining Pty Ltd')
adani = Group.find_or_create_by(name: 'Adani Mining Pty Ltd')
carmichael = Group.find_or_create_by(name: 'Carmichael Rail Network')
obeid_family = Group.find_or_create_by(name: 'Obeid Fanily')
australia_water = Group.find_or_create_by(name: 'Australian Water')




# Membership.create(owner: federal_government, member: the_coalition)
Membership.find_or_create_by(group: the_coalition, person: josh_frydenburg, title: 'Deputy Leader')
Membership.find_or_create_by(group: the_coalition, person: peter_dutton, title: 'Leader')
Membership.find_or_create_by(group: the_coalition, person: scott_morrison, title: 'Leader')
Membership.find_or_create_by(group: the_coalition, person: trent_twomey, title: 'Member')
Membership.find_or_create_by(group: the_coalition, person: warren_entsch, title: 'Member')
Membership.find_or_create_by(group: the_coalition, person: arthur_sinodinos, title: 'Senator')


Membership.find_or_create_by(group: labor, person: anthony_albanese, title: 'Leader')
Membership.find_or_create_by(group: labor, person: tanya_plibersek, title: 'Deputy Leader')
Membership.find_or_create_by(group: labor, person: kevin_rudd, title: 'Leader')
Membership.find_or_create_by(group: labor, person: eddie_obeid, title: 'MLC')
Membership.find_or_create_by(group: the_greens, person: bob_brown, title: 'Great Grand Leader')
Membership.find_or_create_by(group: allegra_spender_campaign, person: allegra_spender)
Membership.find_or_create_by(group: zalie_stegall_campaign, person: zalie_stegall)

Membership.find_or_create_by(group: guide_dogs_victoria, person: sandro_cirianni, title: 'General Manager')
Membership.find_or_create_by(group: guide_dogs_victoria, person: karen_hayes, title: 'Chief Executive Officer')
Membership.find_or_create_by(group: guide_dogs_victoria, person: iain_edwards, title: 'Board Chair')
Membership.find_or_create_by(group: wheelton_investments, person: paul_wheelton, title: 'Owner')
Membership.find_or_create_by(group: climate200, person: simon_holmes_acourt, title: 'Owner')
Membership.find_or_create_by(group: atlassian, person: mike_cannon_brookes, title: 'Owner')
Membership.find_or_create_by(group: atlassian, person: scott_farquar, title: 'Owner')

Membership.find_or_create_by(group: frydenburg_family, person: josh_frydenburg, title: 'Husband')
Membership.find_or_create_by(group: frydenburg_family, person: amie_frydenburg, title: 'Wife')
Membership.find_or_create_by(group: lander_and_rogers, person: amie_frydenburg, title: 'Partner')

Membership.find_or_create_by(group: the_pharmacy_guild, person: trent_twomey, title: 'Member')

Membership.find_or_create_by(group: warren_entsch_campaign, person: warren_entsch, title: 'Member')
Membership.find_or_create_by(group: warren_entsch_campaign, person: trent_twomey, title: 'Campaign Manager')

Membership.find_or_create_by(group: twomey_family, person: georgina_twomey, title: 'Wife')
Membership.find_or_create_by(group: twomey_family, person: trent_twomey, title: 'Husband')

Membership.find_or_create_by(group: qrx_group, person: georgina_twomey, title: 'Part Owner')
Membership.find_or_create_by(group: qrx_group, person: leo_maltam, title: 'Director')
Membership.find_or_create_by(group: qrx_group, person: junior_entsch)

Membership.find_or_create_by(group: australian_romance, person: sally_zou)
Membership.find_or_create_by(group: aus_gold_mining, person: sally_zou)

Membership.find_or_create_by(group: entsch_family, person: warren_entsch, title: 'Dad')
Membership.find_or_create_by(group: entsch_family, person: junior_entsch, title: 'Son')

Membership.find_or_create_by(group: oryxium, person: david_lowy, title: 'Owner')
Membership.find_or_create_by(group: oryxium, person: peter_lowy, title: 'Owner')
Membership.find_or_create_by(group: oryxium, person: steven_lowy, title: 'Owner')

Membership.find_or_create_by(group: obeid_family, person: eddie_obeid, title: 'Father')
Membership.find_or_create_by(group: obeid_family, person: moses_obeid, title: 'Son / Brother')
Membership.find_or_create_by(group: australia_water, person: moses_obeid, title: 'Director')
Membership.find_or_create_by(group: australia_water, person: arthur_sinodinos, title: 'Director')


Affiliation.create(owning_group: adani, sub_group: carmichael)


Transfer.find_or_create_by(
  giver: federal_government,
  taker: guide_dogs_victoria,
  effective_date: Date.new(2020, 4, 1),
  transfer_type: 'grant',
  amount: 25_000_000
)


Transfer.find_or_create_by(
  giver: guide_dogs_victoria,
  taker: lander_and_rogers,
  effective_date: Date.new(2022, 4, 1),
  transfer_type: 'fees',
  amount: 140000
)

Transfer.find_or_create_by(
  giver: paul_wheelton,
  taker: the_coalition,
  effective_date: Date.new(2018, 6, 30),
  transfer_type: 'donation',
  amount: 60000
)

Transfer.find_or_create_by(
  giver: wheelton_investments,
  taker: the_coalition,
  effective_date: Date.new(2019, 6, 30),
  transfer_type: 'donation',
  amount: 27617
)

Transfer.find_or_create_by(
  giver: scott_farquar,
  taker: climate200,
  effective_date: Date.new(2022, 6, 30),
  transfer_type: 'donation',
  amount: 1_500_000
)

Transfer.find_or_create_by(
  giver: climate200,
  taker: zalie_stegall_campaign,
  effective_date: Date.new(2022, 6, 30),
  transfer_type: 'donation',
  amount: 25_000
)

Transfer.find_or_create_by(
  giver: mike_cannon_brookes,
  taker: climate200,
  effective_date: Date.new(2022, 6, 30),
  transfer_type: 'donation',
  amount: 1_115_000
)

Transfer.find_or_create_by(
  giver: federal_government,
  taker: qrx_group,
  effective_date: Date.new(2022, 6, 30),
  transfer_type: 'grant',
  amount: 2_415_400
)

# Transfer.find_or_create_by(
#   giver: lander_and_rogers,
#   taker: amie_frydenburg,
#   effective_date: Date.new(2022, 6, 30),
#   transfer_type: 'salary',
#   amount: 1
# )



