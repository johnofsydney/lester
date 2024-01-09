
Transfer.destroy_all
Membership.destroy_all
Group.destroy_all
Person.destroy_all


john = Person.create(name: 'John')
mark = Person.create(name: 'Mark')
ben = Person.create(name: 'Ben')
paul = Person.create(name: 'Paul')
richard = Person.create(name: 'Richard')

doe = Person.create(name: 'John Doe')
pedro = Person.create(name: 'Pedro')

eddie = Person.create(name: 'Eddie')

alp = Group.create(name: 'Australian Labor Party')
aloyisus = Group.create(name: 'Aloyisus')
usyd = Group.create(name: 'University of Sydney')
balance = Group.create(name: 'Balance')
kennards = Group.create(name: 'Kennards')
greens = Group.create(name: 'The Greens')
doeboys = Group.create(name: 'Dough')

Membership.create(group: alp, person: john, title: 'Member', start_date: 2.years.ago)
Membership.create(group: alp, person: eddie, title: 'Member', start_date: 25.years.ago, end_date: 10.years.ago)

Membership.create(group: usyd, person: john, title: 'Student', start_date: 34.years.ago, end_date: 30.years.ago)
Membership.create(group: usyd, person: mark, title: 'Student', start_date: 34.years.ago, end_date: 30.years.ago)
Membership.create(group: usyd, person: ben, title: 'Student', start_date: 34.years.ago, end_date: 30.years.ago)
Membership.create(group: usyd, person: richard, title: 'Student', start_date: 34.years.ago, end_date: 30.years.ago)
Membership.create(group: usyd, person: doe, title: 'Student', start_date: 4.years.ago, end_date: 2.years.ago)

Membership.create(group: aloyisus, person: paul, title: 'Student', start_date: 40.years.ago, end_date: 35.years.ago)
Membership.create(group: aloyisus, person: ben, title: 'Student', start_date: 40.years.ago, end_date: 35.years.ago)
Membership.create(group: aloyisus, person: richard, title: 'Student', start_date: 40.years.ago, end_date: 35.years.ago)

Membership.create(group: balance, person: paul, title: 'Owner', start_date: 16.years.ago)
Membership.create(group: kennards, person: richard, title: 'CIO', start_date: 6.years.ago)
Membership.create(group: doeboys, person: doe, title: 'Member', start_date: 2.years.ago)

Transfer.create(giver: balance, taker: greens, amount: 1000, effective_date: 2.years.ago)
Transfer.create(giver: kennards, taker: greens, amount: 1000, effective_date: 2.years.ago)
Transfer.create(giver: paul, taker: alp, amount: 1000, effective_date: 20.years.ago)





# # Transaction.destroy_all

# josh_frydenburg = Person.find_or_create_by(name: 'Josh Frydenburg')
# # peter_dutton = Person.find_or_create_by(name: 'Peter Dutton')
# # scott_morrison = Person.find_or_create_by(name: 'Scott Morrison')
# warren_entsch = Person.find_or_create_by(name: 'Warren Entsch')
# arthur_sinodinos = Person.find_or_create_by(name: 'Arthur Sinodinos')
# # bill_heffernan = Person.find_or_create_by(name: 'Bill Heffernan')

# jacob_entsch = Person.find_or_create_by(name: 'Jacob Entsch')
# leo_maltam = Person.find_or_create_by(name: 'Leo Maltam')

# trent_twomey = Person.find_or_create_by(name: 'Trent Twomey')
# # david_heffernan = Person.find_or_create_by(name: 'David Heffernan')
# # adele_tahan = Person.find_or_create_by(name: 'Adele Tahan')
# # judith_plunkett = Person.find_or_create_by(name: 'Judith Plunkett')

# # anthony_albanese = Person.find_or_create_by(name: 'Anthony Albanese')
# # tanya_plibersek = Person.find_or_create_by(name: 'Tanya Plibersek')
# kevin_rudd = Person.find_or_create_by(name: 'Kevin Rudd')
# mark_latham = Person.find_or_create_by(name: 'Mark Latham')
# eddie_obied = Person.find_or_create_by(name: 'Eddie Obied')
# # ian_macdonald = Person.find_or_create_by(name: 'Ian Macdonald')
# # joe_tripodi = Person.find_or_create_by(name: 'Joe Tripodi')

# # nick_di_giralomo = Person.find_or_create_by(name: 'Di Girolamo')
# eddie_obied_junior = Person.find_or_create_by(name: 'Eddie Obied Junior')
# moses_obeid = Person.find_or_create_by(name: 'Moses Obied')
# paul_obeid = Person.find_or_create_by(name: 'Paul Obied')
# gerard_obeid = Person.find_or_create_by(name: 'Gerard Obied')


# # bob_brown = Person.find_or_create_by(name: 'Bob Brown')
# # allegra_spender = Person.find_or_create_by(name: 'Allegra Spender')
# # zalie_stegall = Person.find_or_create_by(name: 'Zali Stegall')
# pauline_hanson = Person.find_or_create_by(name: 'Pauline Hanson')

# paul_wheelton = Person.find_or_create_by(name: 'Paul Wheelton')
# # scott_farquar = Person.find_or_create_by(name: 'Scott Farquar')
# # mike_cannon_brookes = Person.find_or_create_by(name: 'Mike Cannon-Brookes')
# # simon_holmes_acourt = Person.find_or_create_by(name: 'Simon Holmes a Court')

# amie_frydenburg = Person.find_or_create_by(name: 'Amie Frydenburg')
# georgina_twomey = Person.find_or_create_by(name: 'Georgina Twomey')

# # sally_zou = Person.find_or_create_by(name: 'Sally Zou')

# # peter_lowy = Person.find_or_create_by(name: 'Peter Lowy')
# # steven_lowy = Person.find_or_create_by(name: 'Steven Lowy')
# # david_lowy = Person.find_or_create_by(name: 'David Lowy')
# # sandro_cirianni = Person.find_or_create_by(name: 'Sandro Cirianni')
# # karen_hayes = Person.find_or_create_by(name: 'Karen Hayes')
# # iain_edwards = Person.find_or_create_by(name: 'Iain Edwards')


# wheelton_investments = Group.find_or_create_by(name: 'Wheelton Investments Pty Ltd')
# guide_dogs_victoria = Group.find_or_create_by(name: 'Guide Dogs Victoria')
# the_coalition = Group.find_or_create_by(name: 'The Coalition')
# labor = Group.find_or_create_by(name: 'Australian Labor Party')
# # the_greens = Group.find_or_create_by(name: 'The Greens')
# # atlassian = Group.find_or_create_by(name: 'Atlassian')
# # climate200 = Group.find_or_create_by(name: 'Climate 200')
# # teal_independents = Group.find_or_create_by(name: 'Teal Independents')
# # allegra_spender_campaign = Group.find_or_create_by(name: 'Allegra Spender Campaign')
# # zalie_stegall_campaign = Group.find_or_create_by(name: 'Zali Stegall Campaign')
# one_nation = Group.find_or_create_by(name: "Pauline Hanson's One Nation")




# lander_and_rogers = Group.find_or_create_by(name: 'Lander and Rogers')
# the_pharmacy_guild = Group.find_or_create_by(name: 'The Pharmacy Guild Of Australia')
# warren_entsch_campaign = Group.find_or_create_by(name: 'Warren Entsch Campaign')
# qrx_group = Group.find_or_create_by(name: 'QRX Group 1')

# frydenburg_family = Group.find_or_create_by(name: 'Frydenburg Family')
# twomey_family = Group.find_or_create_by(name: 'Twomey Family')
# entsch_family = Group.find_or_create_by(name: 'Entsch Family')
# obeid_family = Group.find_or_create_by(name: 'Obeid Family')
# # heffernan_family = Group.find_or_create_by(name: 'Heffernan Family')

# # australian_romance = Group.find_or_create_by(name: 'Australian Romance Pty Ltd')
# # aus_gold_mining = Group.find_or_create_by(name: 'AusGold Mining')
# # oryxium = Group.find_or_create_by(name: 'Oryxium Investments Limited')
# # adani = Group.find_or_create_by(name: 'Adani Mining Pty Ltd')
# # carmichael = Group.find_or_create_by(name: 'Carmichael Rail Network')
# australian_water_holdings = Group.find_or_create_by(name: 'Australian Water Holdings Pty Ltd')
# # colin_biggers_and_paisley = Group.find_or_create_by(name: 'Colin Biggers & Paisley')
# # sunny_ridge_strawberry_farm = Group.find_or_create_by(name: 'Sunny Ridge Strawberry Farm')
# # waratah_group = Group.find_or_create_by(name: 'Waratah Group (Australia) Pty Ltd)')


# federal_government = Group.find_or_create_by(name: 'Australian Federal Government')
# # nsw_upper_house = Group.find_or_create_by(name: 'NSW Legislative Council')
# # nsw_lower_house = Group.find_or_create_by(name: 'NSW Legislative Assembly')
# # the_terrigals = Group.find_or_create_by(name: 'The Terrigals')


# # Membership.create(owner: federal_government, member: the_coalition)
# Membership.create(group: the_coalition, person: josh_frydenburg, title: 'Deputy Leader')
# # Membership.create(group: the_coalition, person: peter_dutton, title: 'Leader')
# # Membership.create(group: the_coalition, person: scott_morrison, title: 'Leader')
# Membership.create(group: the_coalition, person: trent_twomey, title: 'Branch Member')
# Membership.create(group: the_coalition, person: warren_entsch, title: 'Member')
# Membership.create(group: the_coalition, person: arthur_sinodinos, title: 'Member')
# # Membership.create(group: the_coalition, person: bill_heffernan, title: 'Member')


# # Membership.create(group: labor, person: anthony_albanese, title: 'Leader', start_date: Date.new(2019, 5, 30))
# # Membership.create(group: labor, person: tanya_plibersek, title: 'Deputy Leader', start_date: Date.new(2019, 5, 30))
# Membership.create(group: labor, person: kevin_rudd, title: 'Leader', start_date: Date.new(2006, 12, 4), end_date: Date.new(2010, 6, 24))
# Membership.create(group: labor, person: mark_latham, title: 'Leader', start_date: Date.new(2003, 12, 2), end_date: Date.new(2005, 1, 18))
# # Membership.create(group: labor, person: ian_macdonald, title: 'MLC', start_date: Date.new(1988, 3, 19), end_date: Date.new(2010, 6, 7))
# Membership.create(group: labor, person: eddie_obied, title: 'MLC', start_date: Date.new(1991, 5, 6), end_date: Date.new(2011, 5, 6))
# # Membership.create(group: labor, person: adele_tahan, title: 'Member')

# # Membership.create(group: the_greens, person: bob_brown, title: 'Great Grand Poobah')
# # Membership.create(group: allegra_spender_campaign, person: allegra_spender)
# # Membership.create(group: zalie_stegall_campaign, person: zalie_stegall)

# # Membership.create(group: guide_dogs_victoria, person: sandro_cirianni, title: 'General Manager')
# # Membership.create(group: guide_dogs_victoria, person: karen_hayes, title: 'Chief Executive Officer')
# # Membership.create(group: guide_dogs_victoria, person: iain_edwards, title: 'Board Chair')
# Membership.create(group: wheelton_investments, person: paul_wheelton, title: 'Owner')
# # Membership.create(group: climate200, person: simon_holmes_acourt, title: 'Owner')
# # Membership.create(group: atlassian, person: mike_cannon_brookes, title: 'Owner')
# # Membership.create(group: atlassian, person: scott_farquar, title: 'Owner')

# Membership.create(group: frydenburg_family, person: josh_frydenburg, title: 'Husband')
# Membership.create(group: frydenburg_family, person: amie_frydenburg, title: 'Wife')
# Membership.create(group: lander_and_rogers, person: amie_frydenburg, title: 'Partner')

# Membership.create(group: the_pharmacy_guild, person: trent_twomey, title: 'National President')
# # Membership.create(group: the_pharmacy_guild, person: david_heffernan, title: 'National Councilor (NSW)')
# # Membership.create(group: the_pharmacy_guild, person: adele_tahan, title: 'National Councilor (NSW)')
# # Membership.create(group: the_pharmacy_guild, person: judith_plunkett, title: 'National Councilor (NSW)')

# Membership.create(group: warren_entsch_campaign, person: warren_entsch, title: 'Member')
# Membership.create(group: warren_entsch_campaign, person: trent_twomey, title: 'Campaign Manager')

# Membership.create(group: twomey_family, person: georgina_twomey, title: 'Wife')
# Membership.create(group: twomey_family, person: trent_twomey, title: 'Husband')

# # Membership.create(group: heffernan_family, person: bill_heffernan, title: 'Father')
# # Membership.create(group: heffernan_family, person: david_heffernan, title: 'Son / Brother')

# Membership.create(group: obeid_family, person: eddie_obied, title: 'Father')
# Membership.create(group: obeid_family, person: eddie_obied_junior, title: 'Son / Brother')
# Membership.create(group: obeid_family, person: moses_obeid, title: 'Son / Brother')
# Membership.create(group: obeid_family, person: paul_obeid, title: 'Son / Brother')
# Membership.create(group: obeid_family, person: gerard_obeid, title: 'Son / Brother')

# Membership.create(group: qrx_group, person: georgina_twomey, title: 'Part Owner')
# Membership.create(group: qrx_group, person: leo_maltam, title: 'Director')
# Membership.create(group: qrx_group, person: jacob_entsch)

# # Membership.create(group: australian_romance, person: sally_zou)
# # Membership.create(group: aus_gold_mining, person: sally_zou)

# Membership.create(group: entsch_family, person: warren_entsch, title: 'Dad')
# Membership.create(group: entsch_family, person: jacob_entsch, title: 'Son')

# # Membership.create(group: oryxium, person: david_lowy, title: 'Owner')
# # Membership.create(group: oryxium, person: peter_lowy, title: 'Owner')
# # Membership.create(group: oryxium, person: steven_lowy, title: 'Owner')

# Membership.create(group: one_nation, person: pauline_hanson, title: 'Leader')
# Membership.create(group: one_nation, person: mark_latham, title: 'NSW Leader', start_date: Date.new(2018, 11, 15), end_date: Date.new(2022, 6, 30))
# # Membership.create(group: nsw_upper_house, person: mark_latham, title: 'MLC', start_date: Date.new(2019, 3, 23))

# # Membership.create(group: the_terrigals, person: joe_tripodi, title: 'Member')
# # Membership.create(group: the_terrigals, person: eddie_obied, title: 'Member')

# Membership.create(group: australian_water_holdings, person: arthur_sinodinos, title: 'Chairman', start_date: Date.new(2008, 1, 1), end_date: Date.new(2011, 5, 6))
# Membership.create(group: australian_water_holdings, person: eddie_obied_junior, title: 'Salaryman', start_date: Date.new(2008, 1, 1), end_date: Date.new(2011, 5, 6))
# # Membership.create(group: australian_water_holdings, person: nick_di_giralomo, title: 'Chief Executive Officer')
# # Membership.create(group: colin_biggers_and_paisley, person: nick_di_giralomo, title: 'Partner')


# # Affiliation.create(owning_group: adani, sub_group: carmichael)
# # Affiliation.create(owning_group: waratah_group, sub_group: sunny_ridge_strawberry_farm)
# # Affiliation.create(owning_group: obeid_family, sub_group: australian_water_holdings)

# # Affiliation.create(owning_group: federal_government, sub_group: labor, start_date: Date.new(2022, 6, 30), end_date: Date.new(2013, 9, 18))
# # Affiliation.create(owning_group: federal_government, sub_group: labor, start_date: Date.new(2007, 12, 3), end_date: Date.new(2013, 9, 18))
# # Affiliation.create(owning_group: federal_government, sub_group: the_coalition, start_date: Date.new(2013, 9, 18), end_date: Date.new(2022, 6, 30))


# # TESTING with made up data
# # company_one = Group.find_or_create_by(name: 'Company One') # take
# # company_two = Group.find_or_create_by(name: 'Company Two') # giver & taker
# # company_three = Group.find_or_create_by(name: 'Company Three') # giver
# # company_four = Group.find_or_create_by(name: 'Old Boys') # neither

# # person_one = Person.find_or_create_by(name: 'Person One')
# # person_two = Person.find_or_create_by(name: 'Person Two')
# # person_three = Person.find_or_create_by(name: 'Person Three')
# # person_four = Person.find_or_create_by(name: 'Person Four')

# # Membership.create(group: company_one, person: person_one, title: 'CEO', start_date: Date.new(2010, 1, 1), end_date: Date.new(2015, 1, 1))
# # Membership.create(group: company_one, person: person_two, title: 'CEO', start_date: Date.new(2015, 1, 2), end_date: Date.new(2020, 1, 1))
# # Membership.create(group: company_one, person: person_three, title: 'Cook', start_date: Date.new(2018, 1, 1), end_date: Date.new(2023, 1, 1))
# # Membership.create(group: company_one, person: person_four, title: 'Officer', start_date: Date.new(2022, 1, 2), end_date: Date.new(2023, 1, 1))


# # Membership.create(group: company_two, person: person_one, title: 'CEO', start_date: Date.new(2015, 1, 2), end_date: Date.new(2020, 1, 1))
# # Membership.create(group: company_two, person: person_two, title: 'CEO', start_date: Date.new(2020, 1, 2), end_date: Date.new(2025, 1, 1))
# # Membership.create(group: company_two, person: person_three, title: 'Cook', start_date: Date.new(2019, 1, 1), end_date: Date.new(2023, 1, 1))


# # Membership.create(group: company_three, person: person_one, title: 'CEO', start_date: Date.new(2020, 1, 2), end_date: Date.new(2021, 1, 1))
# # Membership.create(group: company_three, person: person_three, title: 'Cook', start_date: Date.new(2020, 1, 2), end_date: Date.new(2021, 1, 1))
# # Membership.create(group: company_three, person: person_four, title: 'Cook', start_date: Date.new(2010, 1, 2), end_date: Date.new(2011, 1, 1))

# # Membership.create(group: company_four, person: person_one, title: 'member')
# # Membership.create(group: company_four, person: person_two, title: 'member')
# # Membership.create(group: company_four, person: person_three, title: 'member')
# # Membership.create(group: company_four, person: person_four, title: 'member')

# # Transfer.find_or_create_by(
# #   giver: company_two,
# #   taker: company_one,
# #   effective_date: Date.new(2021, 1, 1),
# #   transfer_type: 'fees',
# #   amount: 1000
# # )
# # Transfer.find_or_create_by(
# #   giver: company_two,
# #   taker: company_one,
# #   effective_date: Date.new(2016, 1, 1),
# #   transfer_type: 'fees',
# #   amount: 2000
# # )
# # Transfer.find_or_create_by(
# #   giver: company_two,
# #   taker: company_one,
# #   effective_date: Date.new(2011, 1, 1),
# #   transfer_type: 'fees',
# #   amount: 3000
# # )
# # Transfer.find_or_create_by(
# #   giver: company_three,
# #   taker: company_one,
# #   effective_date: Date.new(2004, 1, 1),
# #   transfer_type: 'fees',
# #   amount: 4000
# # )
# # Transfer.find_or_create_by(
# #   giver: company_three,
# #   taker: company_one,
# #   effective_date: Date.new(2007, 1, 1),
# #   transfer_type: 'fees',
# #   amount: 5000
# # )
# # Transfer.find_or_create_by(
# #   giver: company_three,
# #   taker: company_one,
# #   effective_date: Date.new(2000, 6, 1),
# #   transfer_type: 'fees',
# #   amount: 6000
# # )
# # Transfer.find_or_create_by(
# #   giver: company_three,
# #   taker: company_two,
# #   effective_date: Date.new(2000, 6, 1),
# #   transfer_type: 'fees',
# #   amount: 7000
# # )
# # Transfer.find_or_create_by(
# #   giver: company_three,
# #   taker: company_two,
# #   effective_date: Date.new(2006, 6, 1),
# #   transfer_type: 'fees',
# #   amount: 8000
# # )



# # TESTING with made up data

# Transfer.find_or_create_by(
#   giver: federal_government,
#   taker: guide_dogs_victoria,
#   effective_date: Date.new(2020, 4, 1),
#   transfer_type: 'grant',
#   amount: 25_000_000
# )


# Transfer.find_or_create_by(
#   giver: guide_dogs_victoria,
#   taker: lander_and_rogers,
#   effective_date: Date.new(2022, 4, 1),
#   transfer_type: 'fees',
#   amount: 140000
# )

# Transfer.find_or_create_by(
#   giver: paul_wheelton,
#   taker: the_coalition,
#   effective_date: Date.new(2018, 6, 30),
#   transfer_type: 'donation',
#   amount: 60000
# )

# Transfer.find_or_create_by(
#   giver: wheelton_investments,
#   taker: the_coalition,
#   effective_date: Date.new(2019, 6, 30),
#   transfer_type: 'donation',
#   amount: 27617
# )

# # Transfer.find_or_create_by(
# #   giver: scott_farquar,
# #   taker: climate200,
# #   effective_date: Date.new(2022, 6, 30),
# #   transfer_type: 'donation',
# #   amount: 1_500_000
# # )

# # Transfer.find_or_create_by(
# #   giver: climate200,
# #   taker: zalie_stegall_campaign,
# #   effective_date: Date.new(2022, 6, 30),
# #   transfer_type: 'donation',
# #   amount: 25_000
# # )

# # Transfer.find_or_create_by(
# #   giver: mike_cannon_brookes,
# #   taker: climate200,
# #   effective_date: Date.new(2022, 6, 30),
# #   transfer_type: 'donation',
# #   amount: 1_115_000
# # )

# Transfer.find_or_create_by(
#   giver: federal_government,
#   taker: qrx_group,
#   effective_date: Date.new(2022, 6, 30),
#   transfer_type: 'grant',
#   amount: 2_415_400
# )

# # Transfer.find_or_create_by(
# #   giver: lander_and_rogers,
# #   taker: amie_frydenburg,
# #   effective_date: Date.new(2022, 6, 30),
# #   transfer_type: 'salary',
# #   amount: 1
# # )



