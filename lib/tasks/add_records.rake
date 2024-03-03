namespace :lester do
  desc 'Destroy All Records'
  task destroy_all: :environment do
    Transfer.destroy_all
    Affiliation.destroy_all
    Membership.destroy_all
    Group.destroy_all
    Person.destroy_all

    ActiveRecord::Base.connection.reset_pk_sequence!('transfers')
    ActiveRecord::Base.connection.reset_pk_sequence!('affiliations')
    ActiveRecord::Base.connection.reset_pk_sequence!('memberships')
    ActiveRecord::Base.connection.reset_pk_sequence!('groups')
    ActiveRecord::Base.connection.reset_pk_sequence!('people')
  end

  desc "Generate a report of users who logged in during the last week"
  task populate: :environment do
    donation_files = [
      'csv_data/Annual_Donations_Made_2018.csv',
      'csv_data/Annual_Donations_Made_2019.csv',
      'csv_data/Annual_Donations_Made_2020.csv',
      'csv_data/Annual_Donations_Made_2021.csv',
      'csv_data/Annual_Donations_Made_2022.csv',
      'csv_data/Annual_Donations_Made_2023.csv',
    ]

    other_files = [
      'csv_data/Federal_Members_2024.csv'
    ]

    donation_files.each do |file|
      FileIngestor.annual_donor_ingest(file)
    end

    # others
    other_files.each do |file|
      FileIngestor.federal_parliamentarians_upload(file)
    end

    p "creating people"
    # coalition members
    josh_frydenburg = Person.find_or_create_by(name: 'Josh Frydenburg')
    peter_dutton = Person.find_or_create_by(name: 'Peter Dutton')
    scott_morrison = Person.find_or_create_by(name: 'Scott Morrison')
    warren_entsch = Person.find_or_create_by(name: 'Warren Entsch')
    arthur_sinodinos = Person.find_or_create_by(name: 'Arthur Sinodinos')
    bill_heffernan = Person.find_or_create_by(name: 'Bill Heffernan')
    barnaby_joyce = Person.find_or_create_by(name: 'Barnaby Joyce')
    malcolm_turnbull = Person.find_or_create_by(name: 'Malcolm Turnbull')
    tony_abbott = Person.find_or_create_by(name: 'Tony Abbot')
    michael_mccormack = Person.find_or_create_by(name: 'MICHAEL MCCORMACK'.titleize)

    # labor members
    anthony_albanese = Person.find_or_create_by(name: 'Anthony Albanese')
    tanya_plibersek = Person.find_or_create_by(name: 'Tanya Plibersek')
    kevin_rudd = Person.find_or_create_by(name: 'Kevin Rudd')
    mark_latham = Person.find_or_create_by(name: 'Mark Latham')
    eddie_obied = Person.find_or_create_by(name: 'Eddie Obied')
    ian_macdonald = Person.find_or_create_by(name: 'Ian Macdonald')
    joe_tripodi = Person.find_or_create_by(name: 'Joe Tripodi')
    adele_tahan = Person.find_or_create_by(name: 'Adele Tahan')
    penny_wong = Person.find_or_create_by(name: 'Penny Wong')

    # minor party members
    bob_brown = Person.find_or_create_by(name: 'Bob Brown')
    allegra_spender = Person.find_or_create_by(name: 'Allegra Spender')
    zalie_stegall = Person.find_or_create_by(name: 'Zali Stegall')
    pauline_hanson = Person.find_or_create_by(name: 'Pauline Hanson')


    # business people
    peter_lowy = Person.find_or_create_by(name: 'Peter Lowy')
    steven_lowy = Person.find_or_create_by(name: 'Steven Lowy')
    david_lowy = Person.find_or_create_by(name: 'David Lowy')
    sandro_cirianni = Person.find_or_create_by(name: 'Sandro Cirianni')
    karen_hayes = Person.find_or_create_by(name: 'Karen Hayes')
    iain_edwards = Person.find_or_create_by(name: 'Iain Edwards')
    paul_wheelton = Person.find_or_create_by(name: 'Paul Wheelton')
    scott_farquar = Person.find_or_create_by(name: 'Scott Farquar')
    mike_cannon_brookes = Person.find_or_create_by(name: 'Mike Cannon-Brookes')
    simon_holmes_acourt = Person.find_or_create_by(name: 'Simon Holmes a Court')
    sally_zou = Person.find_or_create_by(name: 'Sally Zou')
    gina_rinehart = Person.find_or_create_by(name: 'Gina Rinehart')
    isaac_wakil = Person.find_or_create_by(name: 'Isaac Wakil')

    # Great Barrier Reef Foundation
    anna_marsden = Person.find_or_create_by(name: 'Anna Marsden')
    theresa_fyffe = Person.find_or_create_by(name: 'Theresa Fyffe')
    margot_andersen = Person.find_or_create_by(name: 'Margot Andersen')
    cherrie_wilson = Person.find_or_create_by(name: 'Cherrie Wilson')
    david_thodey = Person.find_or_create_by(name: 'David Thodey')
    martin_parkinson = Person.find_or_create_by(name: 'Martin Parkinson')
    stephen_fitzgerald = Person.find_or_create_by(name: 'Stephen Fitzgerald')
    paul_greenfield = Person.find_or_create_by(name: 'Paul Greenfield')
    cindy_hook = Person.find_or_create_by(name: 'Cindy Hook')
    grant_king = Person.find_or_create_by(name: 'Grant King')
    russell_reichelt = Person.find_or_create_by(name: 'Russell Reichelt')
    steven_sargent = Person.find_or_create_by(name: 'Steven Sargent')
    phillip_strachan = Person.find_or_create_by(name: 'Phillip Strachan')
    olivia_wirth = Person.find_or_create_by(name: 'Olivia Wirth')
    hayley_baillie = Person.find_or_create_by(name: 'Hayley Baillie')
    larry_marshall = Person.find_or_create_by(name: 'Larry Marshall')
    katherine_woodthorpe = Person.find_or_create_by(name: 'Katherine Woodthorpe')

    # family members
    eddie_obied_junior = Person.find_or_create_by(name: 'Eddie Obied Junior')
    moses_obeid = Person.find_or_create_by(name: 'Moses Obied')
    paul_obeid = Person.find_or_create_by(name: 'Paul Obied')
    gerard_obeid = Person.find_or_create_by(name: 'Gerard Obied')
    jacob_entsch = Person.find_or_create_by(name: 'Jacob Entsch')
    david_heffernan = Person.find_or_create_by(name: 'David Heffernan')
    amie_frydenburg = Person.find_or_create_by(name: 'Amie Frydenburg')
    georgina_twomey = Person.find_or_create_by(name: 'Georgina Twomey')


    # people who are principally lobbyists, grifters
    leo_maltam = Person.find_or_create_by(name: 'Leo Maltam')
    trent_twomey = Person.find_or_create_by(name: 'Trent Twomey')
    judith_plunkett = Person.find_or_create_by(name: 'Judith Plunkett')
    nick_di_giralomo = Person.find_or_create_by(name: 'Di Girolamo')


    # people of unknown provenance
    russell_webb = Person.find_or_create_by(name: 'Russell Webb')
    bede_burke = Person.find_or_create_by(name: 'Bede Burke')


    p "creating groups"
    # political parties (with state branches)
    the_coalition_federal = Group.find_or_create_by(name: Group::NAMES.coalition.federal)
    liberal_federal = Group.find_or_create_by(name: Group::NAMES.liberals.federal)
    nationals_federal = Group.find_or_create_by(name: Group::NAMES.nationals.federal)
    labor_federal = Group.find_or_create_by(name: Group::NAMES.labor.federal)
    greens_federal = Group.find_or_create_by(name: Group::NAMES.greens.federal)

    liberal_nsw = Group.find_or_create_by(name: Group::NAMES.liberals.nsw)
    nationals_nsw = Group.find_or_create_by(name: Group::NAMES.nationals.nsw)
    the_coalition_nsw = Group.find_or_create_by(name: Group::NAMES.coalition.nsw)
    labor_nsw = Group.find_or_create_by(name: Group::NAMES.labor.nsw)
    greens_nsw = Group.find_or_create_by(name: Group::NAMES.greens.nsw)

    liberal_sa = Group.find_or_create_by(name: Group::NAMES.liberals.sa)
    nationals_sa = Group.find_or_create_by(name: Group::NAMES.nationals.sa)
    the_coalition_sa = Group.find_or_create_by(name: Group::NAMES.coalition.sa)
    labor_sa = Group.find_or_create_by(name: Group::NAMES.labor.sa)
    greens_sa = Group.find_or_create_by(name: Group::NAMES.greens.sa)

    liberal_vic = Group.find_or_create_by(name: Group::NAMES.liberals.vic)
    nationals_vic = Group.find_or_create_by(name: Group::NAMES.nationals.vic)
    the_coalition_vic = Group.find_or_create_by(name: Group::NAMES.coalition.vic)
    labor_vic = Group.find_or_create_by(name: Group::NAMES.labor.vic)
    greens_vic = Group.find_or_create_by(name: Group::NAMES.greens.vic)

    liberal_tas = Group.find_or_create_by(name: Group::NAMES.liberals.tas)
    nationals_tas = Group.find_or_create_by(name: Group::NAMES.nationals.tas)
    the_coalition_tas = Group.find_or_create_by(name: Group::NAMES.coalition.tas)
    labor_tas = Group.find_or_create_by(name: Group::NAMES.labor.tas)
    greens_tas = Group.find_or_create_by(name: Group::NAMES.greens.tas)

    liberal_wa = Group.find_or_create_by(name: Group::NAMES.liberals.wa)
    nationals_wa = Group.find_or_create_by(name: Group::NAMES.nationals.wa)
    the_coalition_wa = Group.find_or_create_by(name: Group::NAMES.coalition.wa)
    labor_wa = Group.find_or_create_by(name: Group::NAMES.labor.wa)
    greens_wa = Group.find_or_create_by(name: Group::NAMES.greens.wa)

    liberal_act = Group.find_or_create_by(name: Group::NAMES.liberals.act)
    nationals_act = Group.find_or_create_by(name: Group::NAMES.nationals.act)
    the_coalition_act = Group.find_or_create_by(name: Group::NAMES.coalition.act)
    labor_act = Group.find_or_create_by(name: Group::NAMES.labor.act)
    greens_act = Group.find_or_create_by(name: Group::NAMES.greens.act)

    liberal_qld = Group.find_or_create_by(name: Group::NAMES.liberals.qld)
    labor_qld = Group.find_or_create_by(name: Group::NAMES.labor.qld)
    greens_qld = Group.find_or_create_by(name: Group::NAMES.greens.qld)

    liberal_nt = Group.find_or_create_by(name: Group::NAMES.liberals.nt)
    labor_nt = Group.find_or_create_by(name: Group::NAMES.labor.nt)
    greens_nt = Group.find_or_create_by(name: Group::NAMES.greens.nt)



    # factions
    the_terrigals = Group.find_or_create_by(name: 'The Terrigals')

    # smaller politcal parties, campaign groups
    allegra_spender_campaign = Group.find_or_create_by(name: 'Allegra Spender Campaign')
    zalie_stegall_campaign = Group.find_or_create_by(name: 'Zali Stegall Campaign')
    warren_entsch_campaign = Group.find_or_create_by(name: 'Warren Entsch Campaign')
    one_nation = Group.find_or_create_by(name: "Pauline Hanson's One Nation")
    climate200 = Group.find_or_create_by(name: 'Climate 200')

    # companies
    atlassian = Group.find_or_create_by(name: 'Atlassian')
    lander_and_rogers = Group.find_or_create_by(name: 'Lander and Rogers')
    qrx_group = Group.find_or_create_by(name: 'QRX Group 1')
    australian_romance = Group.find_or_create_by(name: 'Australian Romance Pty Ltd')
    aus_gold_mining = Group.find_or_create_by(name: 'AusGold Mining')
    oryxium = Group.find_or_create_by(name: 'Oryxium Investments Limited')
    adani = Group.find_or_create_by(name: 'Adani Mining Pty Ltd')
    carmichael = Group.find_or_create_by(name: 'Carmichael Rail Network')
    australian_water_holdings = Group.find_or_create_by(name: 'Australian Water Holdings Pty Ltd')
    colin_biggers_and_paisley = Group.find_or_create_by(name: 'Colin Biggers & Paisley')
    sunny_ridge_strawberry_farm = Group.find_or_create_by(name: 'Sunny Ridge Strawberry Farm')
    waratah_group = Group.find_or_create_by(name: 'Waratah Group (Australia) Pty Ltd)')
    wheelton_investments = Group.find_or_create_by(name: 'Wheelton Investments Pty Ltd')
    guide_dogs_victoria = Group.find_or_create_by(name: 'Guide Dogs Victoria')
    hancock_prospecting = Group.find_or_create_by(name: 'Hancock Prospecting Pty Ltd')
    great_barrier_reef_foundation = Group.find_or_create_by(name: 'Great Barrier Reef Foundation')


    tyro_payments = Group.find_or_create_by(name: 'Tyro Payments')
    xero = Group.find_or_create_by(name: 'Xero')
    ramsay_health_care = Group.find_or_create_by(name: 'Ramsay Health Care')



    # lobby groups, associations of grifters
    the_pharmacy_guild = Group.find_or_create_by(name: 'The Pharmacy Guild Of Australia')
    sugolena = Group.find_or_create_by(name: 'Sugolena')

    # families
    frydenburg_family = Group.find_or_create_by(name: 'Frydenburg Family')
    twomey_family = Group.find_or_create_by(name: 'Twomey Family')
    entsch_family = Group.find_or_create_by(name: 'Entsch Family')
    obeid_family = Group.find_or_create_by(name: 'Obeid Family')
    heffernan_family = Group.find_or_create_by(name: 'Heffernan Family')

    # governments and departments
    federal_government = Group.find_or_create_by(name: 'Australian Federal Government')
    nsw_government = Group.find_or_create_by(name: 'NSW State Government')
    federal_dept_climate_change = Group.find_or_create_by(name: 'Department of Climate Change')
    federal_dept_environment_and_energy = Group.find_or_create_by(name: 'Department of the Environment and Energy')
    federal_dept_climate_change_and_energy_efficiency = Group.find_or_create_by(name: 'Department of Climate Change and Energy Efficiency')
    federal_dept_treasury = Group.find_or_create_by(name: 'Department of The Treasury')
    federal_dept_prime_minister_and_cabinet = Group.find_or_create_by(name: 'Department of The Prime Minister and Cabinet')
    federal_dept_infrastructure_transport_regional_development = Group.find_or_create_by(name: 'Department of Infrastructure, Transport and Regional Development')

    # attendees of maiden speeches
    barnarbys_maiden_speech = Group.find_or_create_by(name: 'Barnarby Joyce Maiden Speech Attendees')


    p "creating memberships"
    # political parties
    sm_libs = Membership.find_or_create_by(group: liberal_federal, person: scott_morrison)
    mt_libs = Membership.find_or_create_by(group: liberal_federal, person: malcolm_turnbull)
    ta_libs = Membership.find_or_create_by(group: liberal_federal, person: tony_abbott)
    jf_libs = Membership.find_or_create_by(group: liberal_federal, person: josh_frydenburg)
    pd_libs = Membership.find_or_create_by(group: liberal_federal, person: peter_dutton)

    tt_libs = Membership.find_or_create_by(group: liberal_qld, person: trent_twomey)
    we_libs = Membership.find_or_create_by(group: liberal_federal, person: warren_entsch)
    as_libs = Membership.find_or_create_by(group: liberal_federal, person: arthur_sinodinos)
    gh_libs = Membership.find_or_create_by(group: liberal_federal, person: bill_heffernan)
    bj_nats = Membership.find_or_create_by(group: nationals_federal, person: barnaby_joyce)
    mm_nats = Membership.find_or_create_by(group: nationals_federal, person: michael_mccormack)

    Position.find_or_create_by(membership: sm_libs, title: 'Leader & Prime Minister', start_date: Date.new(2018, 8, 24), end_date: Date.new(2022, 6, 30))
    Position.find_or_create_by(membership: sm_libs, title: 'Backbencher', start_date: Date.new(2018, 8, 24), end_date: Date.new(2022, 6, 30))
    Position.find_or_create_by(membership: pd_libs, title: 'Leader', start_date: Date.new(2022, 6, 30))


    # ALP Senators, State and past members
    Membership.find_or_create_by(group: labor_federal, person: kevin_rudd, start_date: Date.new(2006, 12, 4), end_date: Date.new(2010, 6, 24))
    Membership.find_or_create_by(group: labor_federal, person: mark_latham, start_date: Date.new(2003, 12, 2), end_date: Date.new(2005, 1, 18))
    Membership.find_or_create_by(group: labor_nsw, person: ian_macdonald, start_date: Date.new(1988, 3, 19), end_date: Date.new(2010, 6, 7))
    Membership.find_or_create_by(group: labor_nsw, person: eddie_obied, start_date: Date.new(1991, 5, 6), end_date: Date.new(2011, 5, 6))
    Membership.find_or_create_by(group: labor_nsw, person: adele_tahan)
    Membership.find_or_create_by(group: labor_federal, person: penny_wong, start_date: Date.new(1988, 7, 3))

    Membership.find_or_create_by(group: greens_tas, person: bob_brown)

    Membership.find_or_create_by(group: one_nation, person: pauline_hanson)
    Membership.find_or_create_by(group: one_nation, person: mark_latham, start_date: Date.new(2018, 11, 15), end_date: Date.new(2022, 6, 30))
    # Membership.find_or_create_by(group: nsw_upper_house, person: mark_latham, title: 'MLC', start_date: Date.new(2019, 3, 23))


    Membership.find_or_create_by(group: allegra_spender_campaign, person: allegra_spender)
    Membership.find_or_create_by(group: zalie_stegall_campaign, person: zalie_stegall)
    Membership.find_or_create_by(group: warren_entsch_campaign, person: warren_entsch)
    Membership.find_or_create_by(group: warren_entsch_campaign, person: trent_twomey)

    # factions
    Membership.find_or_create_by(group: the_terrigals, person: joe_tripodi)
    Membership.find_or_create_by(group: the_terrigals, person: eddie_obied)

    # attendees of maiden speeches
    Membership.find_or_create_by(group: barnarbys_maiden_speech, person: barnaby_joyce)
    Membership.find_or_create_by(group: barnarbys_maiden_speech, person: gina_rinehart)
    Membership.find_or_create_by(group: barnarbys_maiden_speech, person: russell_webb)
    Membership.find_or_create_by(group: barnarbys_maiden_speech, person: bede_burke)


    # families
    Membership.find_or_create_by(group: twomey_family, person: georgina_twomey) #, title: 'Wife')
    Membership.find_or_create_by(group: twomey_family, person: trent_twomey) #, title: 'Husband')
    Membership.find_or_create_by(group: heffernan_family, person: bill_heffernan) #, title: 'Father')
    Membership.find_or_create_by(group: heffernan_family, person: david_heffernan) #, title: 'Son / Brother')
    Membership.find_or_create_by(group: obeid_family, person: eddie_obied) #, title: 'Father')
    Membership.find_or_create_by(group: obeid_family, person: eddie_obied_junior) #, title: 'Son / Brother')
    Membership.find_or_create_by(group: obeid_family, person: moses_obeid) #, title: 'Son / Brother')
    Membership.find_or_create_by(group: obeid_family, person: paul_obeid) #, title: 'Son / Brother')
    Membership.find_or_create_by(group: obeid_family, person: gerard_obeid) #, title: 'Son / Brother')
    Membership.find_or_create_by(group: entsch_family, person: warren_entsch) #, title: 'Dad')
    Membership.find_or_create_by(group: entsch_family, person: jacob_entsch) #, title: 'Son')
    Membership.find_or_create_by(group: frydenburg_family, person: josh_frydenburg) #, title: 'Husband')
    Membership.find_or_create_by(group: frydenburg_family, person: amie_frydenburg) #, title: 'Wife')
    Membership.find_or_create_by(group: lander_and_rogers, person: amie_frydenburg) #, title: 'Partner')

    # businesses
    gdv_sc = Membership.find_or_create_by(group: guide_dogs_victoria, person: sandro_cirianni) #, title: 'General Manager')
    gdv_kh = Membership.find_or_create_by(group: guide_dogs_victoria, person: karen_hayes) #, title: 'Chief Executive Officer')
    gdv_ie = Membership.find_or_create_by(group: guide_dogs_victoria, person: iain_edwards) #, title: 'Board Chair')
    gdv_pw = Membership.find_or_create_by(group: guide_dogs_victoria, person: paul_wheelton) #, title: 'Capital Campaign Chair')
    wi_pw = Membership.find_or_create_by(group: wheelton_investments, person: paul_wheelton) #, title: 'Owner')

    Membership.find_or_create_by(group: sugolena, person: isaac_wakil) #, title: 'Owner')

    Membership.find_or_create_by(group: climate200, person: simon_holmes_acourt) #, title: 'Owner')
    Membership.find_or_create_by(group: atlassian, person: mike_cannon_brookes) #, title: 'Owner')
    Membership.find_or_create_by(group: atlassian, person: scott_farquar) #, title: 'Owner')
    Membership.find_or_create_by(group: the_pharmacy_guild, person: trent_twomey) #, title: 'National President')
    Membership.find_or_create_by(group: the_pharmacy_guild, person: david_heffernan) #, title: 'National Councilor (NSW)')
    Membership.find_or_create_by(group: the_pharmacy_guild, person: adele_tahan) #, title: 'National Councilor (NSW)')
    Membership.find_or_create_by(group: the_pharmacy_guild, person: judith_plunkett) #, title: 'National Councilor (NSW)')
    Membership.find_or_create_by(group: qrx_group, person: georgina_twomey) #, title: 'Part Owner')
    Membership.find_or_create_by(group: qrx_group, person: leo_maltam) #, title: 'Director')
    Membership.find_or_create_by(group: qrx_group, person: jacob_entsch)
    Membership.find_or_create_by(group: australian_romance, person: sally_zou)
    Membership.find_or_create_by(group: aus_gold_mining, person: sally_zou)
    Membership.find_or_create_by(group: oryxium, person: david_lowy) #, title: 'Owner')
    Membership.find_or_create_by(group: oryxium, person: peter_lowy) #, title: 'Owner')
    Membership.find_or_create_by(group: oryxium, person: steven_lowy) #, title: 'Owner')
    Membership.find_or_create_by(group: australian_water_holdings, person: arthur_sinodinos) #, title: 'Chairman', start_date: Date.new(2008, 1, 1), end_date: Date.new(2011, 5, 6))
    Membership.find_or_create_by(group: australian_water_holdings, person: eddie_obied_junior) #, title: 'Salaryman', start_date: Date.new(2008, 1, 1), end_date: Date.new(2011, 5, 6))
    Membership.find_or_create_by(group: australian_water_holdings, person: nick_di_giralomo) #, title: 'Chief Executive Officer')
    Membership.find_or_create_by(group: colin_biggers_and_paisley, person: nick_di_giralomo) #, title: 'Partner')
    Membership.find_or_create_by(group: hancock_prospecting, person: gina_rinehart) #, title: 'Executive Chairwoman')

    Membership.find_or_create_by(group: great_barrier_reef_foundation, person: anna_marsden, positions: [Position.create(title: 'Managing Director')])
    Membership.find_or_create_by(group: great_barrier_reef_foundation, person: david_thodey, positions: [Position.create(title: 'Co-Chair')])
    Membership.find_or_create_by(group: great_barrier_reef_foundation, person: martin_parkinson, positions: [Position.create(title: 'Co_Chair')])
    Membership.find_or_create_by(group: great_barrier_reef_foundation, person: stephen_fitzgerald, positions: [Position.create(title: 'Director')])
    Membership.find_or_create_by(group: great_barrier_reef_foundation, person: paul_greenfield, positions: [Position.create(title: 'Director')])
    Membership.find_or_create_by(group: great_barrier_reef_foundation, person: cindy_hook, positions: [Position.create(title: 'Director')])
    Membership.find_or_create_by(group: great_barrier_reef_foundation, person: grant_king, positions: [Position.create(title: 'Director')])
    Membership.find_or_create_by(group: great_barrier_reef_foundation, person: russell_reichelt, positions: [Position.create(title: 'Director')])
    Membership.find_or_create_by(group: great_barrier_reef_foundation, person: steven_sargent, positions: [Position.create(title: 'Director')])
    Membership.find_or_create_by(group: great_barrier_reef_foundation, person: phillip_strachan, positions: [Position.create(title: 'Director')])
    Membership.find_or_create_by(group: great_barrier_reef_foundation, person: olivia_wirth, positions: [Position.create(title: 'Director')])
    Membership.find_or_create_by(group: great_barrier_reef_foundation, person: hayley_baillie, positions: [Position.create(title: 'Director')])
    Membership.find_or_create_by(group: great_barrier_reef_foundation, person: larry_marshall, positions: [Position.create(title: 'Director')])
    Membership.find_or_create_by(group: great_barrier_reef_foundation, person: katherine_woodthorpe, positions: [Position.create(title: 'Director')])

    # Thodey
    # https://en.wikipedia.org/wiki/David_Thodey
    Membership.find_or_create_by(group: tyro_payments, person: david_thodey, positions: [Position.create(title: 'ChairPerson')])
    Membership.find_or_create_by(group: xero, person: david_thodey, positions: [Position.create(title: 'ChairPerson')])
    Membership.find_or_create_by(group: ramsay_health_care, person: david_thodey, positions: [Position.create(title: 'Board Member')])
    # Parkinson
    # https://en.wikipedia.org/wiki/Martin_Parkinson
    Membership.find_or_create_by(group: federal_dept_climate_change, person: martin_parkinson, start_date: Date.new(2007, 12, 3), end_date: Date.new(2010, 3, 8), positions: [Position.create(title: 'Secretary')])
    Membership.find_or_create_by(group: federal_dept_climate_change_and_energy_efficiency, person: martin_parkinson, start_date: Date.new(2010, 3, 8), end_date: Date.new(2011, 3, 7), positions: [Position.create(title: 'Secretary')])
    Membership.find_or_create_by(group: federal_dept_treasury, person: martin_parkinson, start_date: Date.new(2011, 3, 7), end_date: Date.new(2014, 12, 12), positions: [Position.create(title: 'Secretary')])
    Membership.find_or_create_by(group: federal_dept_prime_minister_and_cabinet, person: martin_parkinson, start_date: Date.new(2016, 1, 23), end_date: Date.new(2019, 8, 30), positions: [Position.create(title: 'Secretary')])

    # Prime Ministers
    Membership.find_or_create_by(
      group: federal_dept_prime_minister_and_cabinet,
      person: tony_abbott,
      positions: [
        Position.create(title: 'Prime Minister')
        ]
      )
    Membership.find_or_create_by(
      group: federal_dept_prime_minister_and_cabinet,
      person: malcolm_turnbull,
      start_date: Date.new(2015, 9, 15),
      end_date: Date.new(2018, 8, 23),
      positions: [
        Position.create(
          title: 'Prime Minister',
          start_date: Date.new(2015, 9, 15),
          end_date: Date.new(2018, 8, 23)
        )
      ]
    )
    Membership.find_or_create_by(
      group: federal_dept_prime_minister_and_cabinet,
      person: scott_morrison,
      start_date: Date.new(2018, 8, 24),
      end_date: Date.new(2022, 5, 23),
      positions: [
        Position.create(
          title: 'Prime Minister',
          start_date: Date.new(2018, 8, 24),
          end_date: Date.new(2022, 5, 23)
        )
      ]
    )
    Membership.find_or_create_by(
      group: federal_dept_prime_minister_and_cabinet,
      person: anthony_albanese,
      start_date: Date.new(2022, 5, 23),
      positions: [
        Position.create(
          title: 'Prime Minister',
          start_date: Date.new(2022, 5, 23)
        )
      ]
    )

    # Ministers
    Membership.find_or_create_by(group: federal_dept_climate_change, person: penny_wong, start_date: Date.new(2007, 12, 3), end_date: Date.new(2010, 3, 8), positions: [Position.create(title: 'Minister')])
    Membership.find_or_create_by(group: federal_dept_environment_and_energy, person: josh_frydenburg, start_date: Date.new(2016, 7, 9), end_date: Date.new(2018, 8, 28), positions: [Position.create(title: 'Minister')])
    Membership.find_or_create_by(group: federal_dept_infrastructure_transport_regional_development, person: michael_mccormack, start_date: Date.new(2018, 8, 28), end_date: Date.new(2021, 6, 22), positions: [Position.create(title: 'Minister')])

    # GDV related
    Position.find_or_create_by(membership: gdv_sc, title: 'General Manager', start_date: Date.new(2018, 4, 1), end_date: Date.new(2022, 6, 30))
    Position.find_or_create_by(membership: gdv_kh, title: 'Chief Executive Officer', start_date: Date.new(2018, 4, 1), end_date: Date.new(2022, 6, 30))
    Position.find_or_create_by(membership: gdv_ie, title: 'Board Chair', start_date: Date.new(2018, 4, 1), end_date: Date.new(2022, 6, 30))
    Position.find_or_create_by(membership: gdv_pw, title: 'Capital Campaign Chair')
    Position.find_or_create_by(membership: wi_pw, title: 'Owner')


    p "creating affiliations"
    Affiliation.find_or_create_by(owning_group: greens_federal, sub_group: greens_nsw)
    Affiliation.find_or_create_by(owning_group: greens_federal, sub_group: greens_vic)
    Affiliation.find_or_create_by(owning_group: greens_federal, sub_group: greens_tas)
    Affiliation.find_or_create_by(owning_group: liberal_federal, sub_group: liberal_nsw)
    Affiliation.find_or_create_by(owning_group: liberal_federal, sub_group: liberal_vic)
    Affiliation.find_or_create_by(owning_group: liberal_federal, sub_group: liberal_tas)
    Affiliation.find_or_create_by(owning_group: liberal_federal, sub_group: liberal_qld)
    Affiliation.find_or_create_by(owning_group: liberal_federal, sub_group: liberal_sa)
    Affiliation.find_or_create_by(owning_group: liberal_federal, sub_group: liberal_nt)
    Affiliation.find_or_create_by(owning_group: liberal_federal, sub_group: liberal_wa)
    Affiliation.find_or_create_by(owning_group: liberal_federal, sub_group: liberal_act)
    Affiliation.find_or_create_by(owning_group: nationals_federal, sub_group: nationals_nsw)
    Affiliation.find_or_create_by(owning_group: nationals_federal, sub_group: nationals_vic)
    Affiliation.find_or_create_by(owning_group: nationals_federal, sub_group: nationals_tas)
    Affiliation.find_or_create_by(owning_group: nationals_federal, sub_group: nationals_sa)
    Affiliation.find_or_create_by(owning_group: nationals_federal, sub_group: nationals_wa)
    Affiliation.find_or_create_by(owning_group: nationals_federal, sub_group: nationals_act)
    Affiliation.find_or_create_by(owning_group: labor_federal, sub_group: labor_nsw)
    Affiliation.find_or_create_by(owning_group: labor_federal, sub_group: labor_vic)
    Affiliation.find_or_create_by(owning_group: labor_federal, sub_group: labor_tas)
    Affiliation.find_or_create_by(owning_group: labor_federal, sub_group: labor_qld)
    Affiliation.find_or_create_by(owning_group: labor_federal, sub_group: labor_sa)
    Affiliation.find_or_create_by(owning_group: labor_federal, sub_group: labor_nt)
    Affiliation.find_or_create_by(owning_group: labor_federal, sub_group: labor_wa)
    Affiliation.find_or_create_by(owning_group: labor_federal, sub_group: labor_act)


    Affiliation.find_or_create_by(owning_group: federal_government, sub_group: federal_dept_climate_change)
    Affiliation.find_or_create_by(owning_group: federal_government, sub_group: federal_dept_environment_and_energy)
    Affiliation.find_or_create_by(owning_group: federal_government, sub_group: federal_dept_treasury)
    Affiliation.find_or_create_by(owning_group: federal_government, sub_group: federal_dept_prime_minister_and_cabinet)



    p "creating transfers"
    Transfer.find_or_create_by(
      giver: federal_dept_infrastructure_transport_regional_development,
      taker: guide_dogs_victoria,
      effective_date: Date.new(2020, 4, 19),
      transfer_type: 'grant',
      amount: 2_500_000,
      evidence: 'https://parlinfo.aph.gov.au/parlInfo/download/media/pressrel/7303441/upload_binary/7303441.pdf;fileType=application/pdf#search=%22media/pressrel/7303441%22'
    )


    # DID THIS PROCEED?
    # https://www.crikey.com.au/2020/02/21/pharmacy-guild-mccormack/
    Transfer.find_or_create_by(
      giver: federal_dept_infrastructure_transport_regional_development,
      taker: qrx_group,
      effective_date: Date.new(2022, 6, 30),
      transfer_type: 'grant',
      amount: 2_415_400,
      evidence: 'https://www.9news.com.au/national/no-conflict-for-lib-staffer-with-grants/1b655e26-39ac-42e8-ad2c-95380e945a29#:~:text=A%20separate%20committee%20decided%20on,%245%20million%20pharmacy%20distribution%20facility.'
    )

    Transfer.find_or_create_by(
      giver: federal_dept_environment_and_energy,
      taker: great_barrier_reef_foundation,
      effective_date: Date.new(2018, 4, 1),
      transfer_type: 'grant',
      amount: 443_000_000,
      evidence: 'https://www.barrierreef.org/uploads/2018-Year-in-Review-straight-format.pdf'
    )
  end
end