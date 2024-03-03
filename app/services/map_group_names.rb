class MapGroupNames

  def initialize(name)
    @name = map_or_return_name(name)
  end

  def call
    @name
  end

  def map_or_return_name(name)
    name = name.strip

    return 'Sugolena' if name.match?(/Sugolena/i)
    return 'Idameneo' if name.match?(/Idameneo/i)
    return 'Get Up' if name.match?(/(GetUp|Get Up)/i)
    return 'Australian Hotels Association' if name.match?(/Australian Hotels Association/i)
    return 'Advance Australia' if name.match?(/Advance Aus/i)
    return "It's Not a Race Limited" if name.match?(/(Not A Race|Note a Race)/i)
    return 'Australian Council of Trade Unions' if name.match?(/ACTU/i)
    return 'Climate 200' if name.match?(/(Climate 200|Climate200)/i)

          # Independents
    return 'David Pocock Campaign' if name.match?(/David Pocock/i)
    return 'Zali Steggall Campaign' if name.match?(/Zali Steggall/i)
    return 'Kim for Canberra' if name.match?(/Kim for Canberra/i)
    return 'Helen Haines Campaign' if name.match?(/Helen Haines/i)

    return 'Liberal Democratic Party' if name.match?(/Liberal.+Democrat/i)
    return "Pauline Hanson's One Nation" if name.match?(/Pauline Hanson/i)
    return 'Shooters, Fishers and Farmers Party' if name.match?(/Shooters, Fishers and Farmers/i)
    return 'Citizens Party' if name.match?(/(Citizens Party|CEC)/i)
    return 'Sustainable Australia Party' if name.match?(/Sustainable Australia/i)
    return 'Centre Alliance' if name.match?(/Centre Alliance/i)
    return 'The Local Party of Australia' if name.match?(/The Local Party of Australia/i)
    return 'Katter Australia Party' if name.match?(/(Katter|KAP)/i)
    return 'Australian Conservatives' if name.match?(/Australian Conservatives/i)
    return 'Federal Independents' if name.match?(/Independent Fed/i)

    # specific exceptions
    return group_names.liberals.federal if name.match(/Liberal Party.+Menzies Research Centre/i)

    # Liberal National Party (QLD) and Country Liberal Party (NT)
    return group_names.liberals.qld if name.match(/(Liberal National Party|LNP).+(QLD|Queensland)/i)
    return group_names.liberals.federal if name.match(/Liberal National Party/i)
    return group_names.liberals.federal if name.match(/Liberal National Fed/i)
    return group_names.liberals.nt if name.match(/Country Liberal.+(NT|N\.T\.|Northern)/i)

    # National Party
    return group_names.nationals.nsw if name.match(/(National Party|NAT).+(NSW|N\.S\.W\.)/i)
    return group_names.nationals.wa if name.match(/(National Party|NAT).+(WA|W\.A\.)/i)
    return group_names.nationals.vic if name.match(/(National Party|NAT).+Vic/i)
    return group_names.nationals.federal if name.match(/National Party.+Fed/i)
    return group_names.nationals.federal if name.match(/The Nationals.+Fed/i)
    return group_names.nationals.federal if name.match(/National.+Fed/i)
    return group_names.nationals.federal if name.match(/NAT-FED/i)
    return group_names.nationals.federal if name.match(/National Party of Australia/i)
    return group_names.nationals.federal if name.match(/Nat Fed/i)

    # Liberals, must come after Liberal Democrats
    return group_names.liberals.nsw if name.match(/Lib.+(NSW|N\.S\.W\.)/i)
    return group_names.liberals.vic if name.match(/Lib.+VIC/i)
    return group_names.liberals.qld if name.match(/Lib.+QLD/i)
    return group_names.liberals.sa if name.match(/Lib.+(South Australia|SA|S\.A\.)/i)
    return group_names.liberals.nt if name.match(/Lib.+(Northern Territory|NT|N\.T\.)/i)
    return group_names.liberals.wa if name.match(/Lib.+(Western Australia|WA|W\.A\.)/i)
    return group_names.liberals.tas if name.match(/Lib.+TAS/i)
    return group_names.liberals.act if name.match(/Lib.+ACT/i)
    return group_names.liberals.federal if name.match(/Lib.+(Fed|FEC)/i)
    return group_names.liberals.federal if name.match(/Lib.+Australia/i)

    # Greens
    return group_names.greens.nsw if name.match(/((Greens|GRN).+(NSW|N\.S\.W)|(NSW|N\.S\.W\.).+(Greens|GRN))/i)
    return group_names.greens.vic if name.match(/((Greens|GRN).+VIC|VIC.+(Greens|GRN))/i)
    return group_names.greens.qld if name.match(/((Greens|GRN).+(QLD|Queensland)|(QLD|Queensland).+(Greens|GRN))/i)
    return group_names.greens.sa if name.match(/((Greens|GRN).+(SA|S\.A\.|South Australia)|(SA|S\.A\.|South Australia).+(Greens|GRN))/i)
    return group_names.greens.nt if name.match(/((Greens|GRN).+(NT|N\.T\.|Northern Territory)|(NT|N\.T\.|Northern Territory).+(Greens|GRN))/i)
    return group_names.greens.wa if name.match(/((Greens|GRN).+(WA|W\.A\.)|(WA|W\.A\.).+(Greens|GRN))/i)
    return group_names.greens.tas if name.match(/((Greens|GRN).+TAS|TAS.+(Greens|GRN))/i)
    return group_names.greens.federal if name.match(/((Greens|GRN).+Fed|Australian (Greens|GRN))/i)

    # Labor
    return group_names.labor.nsw if name.match(/(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(NSW|N\.S\.W\.)/i)
    return group_names.labor.qld if name.match(/(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(QLD|Queensland)/i)
    return group_names.labor.sa if name.match(/(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(SA|S\.A\.|South Australia)/i)
    return group_names.labor.vic if name.match(/(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(VIC|Victoria)/i)
    return group_names.labor.wa if name.match(/(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(WA|W\.A\.|Western Australia)/i)
    return group_names.labor.tas if name.match(/(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(TAS|Tasmania)/i)
    return group_names.labor.act if name.match(/(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(ACT|Australian Capital Territory)/i)
    return group_names.labor.nt if name.match(/(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(NT|N\.T\.|Northern Territory)/i)
    return group_names.labor.federal if name.match(
      /^(?!.*Alpha).*(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)|Labor Fed)/i
    )

    # Can't find it, return the name
    name.titleize
  end

  def group_names
    Group::NAMES
  end
end