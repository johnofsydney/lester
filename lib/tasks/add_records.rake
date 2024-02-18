namespace :lester do
  desc 'Destroy All Records'
  task destroy_all: :environment do
    Transfer.destroy_all
    Affiliation.destroy_all
    Membership.destroy_all
    Group.destroy_all
    Person.destroy_all
  end

  desc "Generate a report of users who logged in during the last week"
  task populate: :environment do

    p "creating people"
    # coalition members
    josh_frydenburg = Person.find_or_create_by(name: 'Josh Frydenburg')
    peter_dutton = Person.find_or_create_by(name: 'Peter Dutton')
    scott_morrison = Person.find_or_create_by(name: 'Scott Morrison')
    warren_entsch = Person.find_or_create_by(name: 'Warren Entsch')
    arthur_sinodinos = Person.find_or_create_by(name: 'Arthur Sinodinos')
    bill_heffernan = Person.find_or_create_by(name: 'Bill Heffernan')
    barnaby_joyce = Person.find_or_create_by(name: 'Barnaby Joyce')

    # labor members
    anthony_albanese = Person.find_or_create_by(name: 'Anthony Albanese')
    tanya_plibersek = Person.find_or_create_by(name: 'Tanya Plibersek')
    kevin_rudd = Person.find_or_create_by(name: 'Kevin Rudd')
    mark_latham = Person.find_or_create_by(name: 'Mark Latham')
    eddie_obied = Person.find_or_create_by(name: 'Eddie Obied')
    ian_macdonald = Person.find_or_create_by(name: 'Ian Macdonald')
    joe_tripodi = Person.find_or_create_by(name: 'Joe Tripodi')
    adele_tahan = Person.find_or_create_by(name: 'Adele Tahan')

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


    # lobby groups, associations of grifters
    the_pharmacy_guild = Group.find_or_create_by(name: 'The Pharmacy Guild Of Australia')

    # families
    frydenburg_family = Group.find_or_create_by(name: 'Frydenburg Family')
    twomey_family = Group.find_or_create_by(name: 'Twomey Family')
    entsch_family = Group.find_or_create_by(name: 'Entsch Family')
    obeid_family = Group.find_or_create_by(name: 'Obeid Family')
    heffernan_family = Group.find_or_create_by(name: 'Heffernan Family')

    # governments
    federal_government = Group.find_or_create_by(name: 'Australian Federal Government')
    nsw_government = Group.find_or_create_by(name: 'NSW State Government')

    # attendees of maiden speeches
    barnarbys_maiden_speech = Group.find_or_create_by(name: 'Barnarby Joyce Maiden Speech Attendees')


    p "creating memberships"
    # political parties
    Membership.find_or_create_by(group: liberal_federal, person: josh_frydenburg)
    Membership.find_or_create_by(group: liberal_federal, person: peter_dutton)
    Membership.find_or_create_by(group: liberal_federal, person: scott_morrison)
    Membership.find_or_create_by(group: liberal_qld, person: trent_twomey Member)
    Membership.find_or_create_by(group: liberal_federal, person: warren_entsch)
    Membership.find_or_create_by(group: liberal_federal, person: arthur_sinodinos)
    Membership.find_or_create_by(group: liberal_federal, person: bill_heffernan)
    Membership.find_or_create_by(group: nationals_federal, person: barnaby_joyce)


    Membership.find_or_create_by(group: labor_federal, person: anthony_albanese, start_date: Date.new(2019, 5, 30))
    Membership.find_or_create_by(group: labor_federal, person: tanya_plibersek, start_date: Date.new(2019, 5, 30))
    Membership.find_or_create_by(group: labor_federal, person: kevin_rudd, start_date: Date.new(2006, 12, 4), end_date: Date.new(2010, 6, 24))
    Membership.find_or_create_by(group: labor_federal, person: mark_latham, start_date: Date.new(2003, 12, 2), end_date: Date.new(2005, 1, 18))
    Membership.find_or_create_by(group: labor_nsw, person: ian_macdonald, start_date: Date.new(1988, 3, 19), end_date: Date.new(2010, 6, 7))
    Membership.find_or_create_by(group: labor_nsw, person: eddie_obied, start_date: Date.new(1991, 5, 6), end_date: Date.new(2011, 5, 6))
    Membership.find_or_create_by(group: labor_nsw, person: adele_tahan)

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
    Membership.find_or_create_by(group: twomey_family, person: georgina_twomey, title: 'Wife')
    Membership.find_or_create_by(group: twomey_family, person: trent_twomey, title: 'Husband')
    Membership.find_or_create_by(group: heffernan_family, person: bill_heffernan, title: 'Father')
    Membership.find_or_create_by(group: heffernan_family, person: david_heffernan, title: 'Son / Brother')
    Membership.find_or_create_by(group: obeid_family, person: eddie_obied, title: 'Father')
    Membership.find_or_create_by(group: obeid_family, person: eddie_obied_junior, title: 'Son / Brother')
    Membership.find_or_create_by(group: obeid_family, person: moses_obeid, title: 'Son / Brother')
    Membership.find_or_create_by(group: obeid_family, person: paul_obeid, title: 'Son / Brother')
    Membership.find_or_create_by(group: obeid_family, person: gerard_obeid, title: 'Son / Brother')
    Membership.find_or_create_by(group: entsch_family, person: warren_entsch, title: 'Dad')
    Membership.find_or_create_by(group: entsch_family, person: jacob_entsch, title: 'Son')
    Membership.find_or_create_by(group: frydenburg_family, person: josh_frydenburg, title: 'Husband')
    Membership.find_or_create_by(group: frydenburg_family, person: amie_frydenburg, title: 'Wife')
    Membership.find_or_create_by(group: lander_and_rogers, person: amie_frydenburg, title: 'Partner')

    # businesses
    Membership.find_or_create_by(group: guide_dogs_victoria, person: sandro_cirianni, title: 'General Manager')
    Membership.find_or_create_by(group: guide_dogs_victoria, person: karen_hayes, title: 'Chief Executive Officer')
    Membership.find_or_create_by(group: guide_dogs_victoria, person: iain_edwards, title: 'Board Chair')
    Membership.find_or_create_by(group: guide_dogs_victoria, person: paul_wheelton, title: 'Capital Campaign Chair')
    Membership.find_or_create_by(group: wheelton_investments, person: paul_wheelton, title: 'Owner')
    Membership.find_or_create_by(group: climate200, person: simon_holmes_acourt, title: 'Owner')
    Membership.find_or_create_by(group: atlassian, person: mike_cannon_brookes, title: 'Owner')
    Membership.find_or_create_by(group: atlassian, person: scott_farquar, title: 'Owner')
    Membership.find_or_create_by(group: the_pharmacy_guild, person: trent_twomey, title: 'National President')
    Membership.find_or_create_by(group: the_pharmacy_guild, person: david_heffernan, title: 'National Councilor (NSW)')
    Membership.find_or_create_by(group: the_pharmacy_guild, person: adele_tahan, title: 'National Councilor (NSW)')
    Membership.find_or_create_by(group: the_pharmacy_guild, person: judith_plunkett, title: 'National Councilor (NSW)')
    Membership.find_or_create_by(group: qrx_group, person: georgina_twomey, title: 'Part Owner')
    Membership.find_or_create_by(group: qrx_group, person: leo_maltam, title: 'Director')
    Membership.find_or_create_by(group: qrx_group, person: jacob_entsch)
    Membership.find_or_create_by(group: australian_romance, person: sally_zou)
    Membership.find_or_create_by(group: aus_gold_mining, person: sally_zou)
    Membership.find_or_create_by(group: oryxium, person: david_lowy, title: 'Owner')
    Membership.find_or_create_by(group: oryxium, person: peter_lowy, title: 'Owner')
    Membership.find_or_create_by(group: oryxium, person: steven_lowy, title: 'Owner')
    Membership.find_or_create_by(group: australian_water_holdings, person: arthur_sinodinos, title: 'Chairman', start_date: Date.new(2008, 1, 1), end_date: Date.new(2011, 5, 6))
    Membership.find_or_create_by(group: australian_water_holdings, person: eddie_obied_junior, title: 'Salaryman', start_date: Date.new(2008, 1, 1), end_date: Date.new(2011, 5, 6))
    Membership.find_or_create_by(group: australian_water_holdings, person: nick_di_giralomo, title: 'Chief Executive Officer')
    Membership.find_or_create_by(group: colin_biggers_and_paisley, person: nick_di_giralomo, title: 'Partner')
    Membership.find_or_create_by(group: hancock_prospecting, person: gina_rinehart, title: 'Executive Chairwoman')


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

    p "creating transfers"
    Transfer.find_or_create_by(
      giver: federal_government,
      taker: guide_dogs_victoria,
      effective_date: Date.new(2020, 4, 19),
      transfer_type: 'grant',
      amount: 2_500_000,
      evidence: 'https://ministers.treasury.gov.au/ministers/josh-frydenberg-2018/media-releases/australian-government-delivers-25-million-support'
    )


    # Transfer.find_or_create_by(
    #   giver: guide_dogs_victoria,
    #   taker: lander_and_rogers,
    #   effective_date: Date.new(2022, 4, 1),
    #   transfer_type: 'fees',
    #   amount: 140000,
    #   evidence:
    # )


    # DID THIS PROCEED?
    # https://www.crikey.com.au/2020/02/21/pharmacy-guild-mccormack/
    Transfer.find_or_create_by(
      giver: federal_government,
      taker: qrx_group,
      effective_date: Date.new(2022, 6, 30),
      transfer_type: 'grant',
      amount: 2_415_400,
      evidence: 'https://www.9news.com.au/national/no-conflict-for-lib-staffer-with-grants/1b655e26-39ac-42e8-ad2c-95380e945a29#:~:text=A%20separate%20committee%20decided%20on,%245%20million%20pharmacy%20distribution%20facility.'
    )

  end
end