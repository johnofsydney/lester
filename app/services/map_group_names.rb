class MapGroupNames

  def initialize(name)
    @name = map_or_return_name(name)
  end

  def call
    @name
  end

  def map_or_return_name(name)
    name = name.strip

    return 'Get Up Limited' if name.match?(/(GetUp|Get Up)/i)
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

    return 'Shooters, Fishers and Farmers Party' if name.match?(/Shooters, Fishers and Farmers/i)
    return 'Citizens Party' if name.match?(/(Citizens Party|CEC)/i)
    return 'Sustainable Australia Party' if name.match?(/Sustainable Australia/i)
    return 'Centre Alliance' if name.match?(/Centre Alliance/i)
    return 'The Local Party of Australia' if name.match?(/The Local Party of Australia/i)
    return 'Katter Australia Party' if name.match?(/(Katter|KAP)/i)
    return 'Australian Conservatives' if name.match?(/Australian Conservatives/i)
    return 'Federal Independents' if name.match?(/Independent Fed/i)
    return 'Lambie Network' if name.match?(/Lambie/i)

    return "Pauline Hanson's One Nation" if name.match?(/Pauline Hanson|One Nation/i)

    # specific exceptions
    return group_names.liberals.federal if name.match(/Liberal Party.+Menzies Research Centre/i)
    return group_names.labor.federal if name.match(/The Australian Labour Party National Secretar/i)
    return group_names.labor.federal if name.match(/ALP National \(ALP-FED\)/i)

    # Liberal National Party (QLD) and Country Liberal Party (NT)
    return group_names.liberals.qld if name.match(/(Liberal National Party|LNP).+(QLD|Queensland)/i)
    return group_names.liberals.federal if name.match(/Liberal National Party/i)
    return group_names.liberals.federal if name.match(/Liberal National Fed/i)
    return group_names.liberals.nt if name.match(/Country Liberal.+(NT|N\.T\.|Northern)/i)

    # National Party
    return group_names.nationals.nsw if name.match(/(National Party|NAT).+(New South Wales|NSW|N\.S\.W\.)/i)
    return group_names.nationals.wa if name.match(/(National Party|NAT).+(Western Australia|WA|W\.A\.)/i)
    return group_names.nationals.vic if name.match(/(National Party|NAT).+Vic/i)
    return group_names.nationals.federal if name.match(/National Party.+Fed/i)
    return group_names.nationals.federal if name.match(/The Nationals.+Fed/i)
    return group_names.nationals.federal if name.match(/Nationals.+Fed/i)
    return group_names.nationals.federal if name.match(/NAT-FED/i)
    return group_names.nationals.federal if name.match(/NAT FED/i)
    return group_names.nationals.federal if name.match(/National Party of Australia/i)
    return group_names.nationals.federal if name.match(/Nat Fed/i)
    return group_names.nationals.federal if name.match(/National Party/i)
    return group_names.nationals.federal if name.match(/National Federal/i)

    # Liberals, must come after Liberal Democrats
    return group_names.liberals.nsw if name.match(/Lib.+(New South Wales|NSW|N\.S\.W\.)/i)
    return group_names.liberals.vic if name.match(/Lib.+VIC/i)
    return group_names.liberals.qld if name.match(/Lib.+(QLD|Queensland)/i)
    return group_names.liberals.sa if name.match(/Lib.+(South Australia|SA|S\.A\.)/i)
    return group_names.liberals.nt if name.match(/Lib.+(Northern Territory|NT|N\.T\.)/i)
    return group_names.liberals.wa if name.match(/Lib.+(Western Australia|Western Australia|WA|W\.A\.)/i)
    return group_names.liberals.tas if name.match(/Lib.+TAS/i)
    return group_names.liberals.act if name.match(/Lib.+(ACT|Australian Capital Territory)/i)
    return group_names.liberals.federal if name.match(/Lib.+(Fed|FEC)/i)
    return group_names.liberals.federal if name.match(/Lib.+Australia/i)
    return group_names.liberals.nsw if name.match(/Liberal Party Avalon/i)
    return group_names.liberals.federal if name.match(/Liberal Party Of Aus/i)

    # Greens
    return group_names.greens.nsw if name.match(/((Greens|GRN).+(New South Wales|NSW|N\.S\.W)|(New South Wales|New South Wales|NSW|N\.S\.W\.).+(Greens|GRN))/i)
    return group_names.greens.vic if name.match(/((Greens|GRN).+VIC|VIC.+(Greens|GRN))/i)
    return group_names.greens.qld if name.match(/((Greens|GRN).+(QLD|Queensland)|(QLD|Queensland).+(Greens|GRN))/i)
    return group_names.greens.sa if name.match(/((Greens|GRN).+(SA|S\.A\.|South Australia)|(SA|S\.A\.|South Australia).+(Greens|GRN))/i)
    return group_names.greens.nt if name.match(/((Greens|GRN).+(NT|N\.T\.|Northern Territory)|(NT|N\.T\.|Northern Territory).+(Greens|GRN))/i)
    return group_names.greens.wa if name.match(/((Greens|GRN).+(Western Australia|WA|W\.A\.)|(Western Australia|WA|W\.A\.).+(Greens|GRN))/i)
    return group_names.greens.tas if name.match(/((Greens|GRN).+TAS|TAS.+(Greens|GRN))/i)
    return group_names.greens.act if name.match(/((Greens|GRN).+ACT|ACT.+(Greens|GRN))/i)
    return group_names.greens.federal if name.match(/((Greens|GRN).+Fed|Australian (Greens|GRN))/i)

    # Labor
    return group_names.labor.nsw if name.match(/(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(New South Wales|NSW|N\.S\.W\.)/i)
    return group_names.labor.qld if name.match(/(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(QLD|Queensland)/i)
    return group_names.labor.sa if name.match(/(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(SA|S\.A\.|South Australia)/i)
    return group_names.labor.vic if name.match(/(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(VIC|Victoria)/i)
    return group_names.labor.act if name.match(/(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(ACT|Australian Capital Territory)/i)
    return group_names.labor.nt if name.match(/(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(NT|N\.T\.|Northern Territory)/i)
    return group_names.labor.wa if name.match(/(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(Western Australia|WA|W\.A\.|Western Australia)/i)
    return group_names.labor.tas if name.match(/(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(Tas)/i)
    return group_names.labor.nsw if name.match(/Labor.+(New South Wales|NSW)/i)
    return group_names.labor.qld if name.match?(/Labor.+(Queensland|QLD)/i)
    return group_names.labor.sa if name.match?(/Labor.+(South Australia|SA)/i)
    return group_names.labor.vic if name.match?(/Labor.+(Victoria|Vic)/i)
    return group_names.labor.wa if name.match?(/Labor.+(Western Australia|WA)/i)
    return group_names.labor.wa if name.match?(/WA ALP/i) # WA ALP
    return group_names.labor.tas if name.match?(/Labor.+(Tasmania|Tas)/i)
    return group_names.labor.act if name.match?(/Labor.+(Australian Capital Territory|ACT)/i)
    return group_names.labor.nt if name.match?(/Labor.+(Northern Territory|NT)/i)
    return group_names.labor.federal if name.match?(/Labor.+Fed/i)
    return group_names.labor.tas if name.match(/Tasmanian.+Labor/i)
    return group_names.labor.federal if name.match?(/Country Labor Party|CLP/i)
    return group_names.labor.federal if name.match?(/Australian Labor Party \(Alp\)/i)
    return group_names.labor.federal if name.match?(/Alp National Secretaria/i)
    return group_names.labor.federal if name.match?(/Alp.+Labor Business Forum/i)
    return group_names.labor.federal if name.match?(/Alp.+Fed/i)
    return group_names.labor.federal if name.match?(/Australian Labor Party/i)
    return group_names.labor.federal if name.match?(/ALP Nat/i)
    return group_names.labor.federal if name.match?(/ALP Bruce Fea/i)

    # Can't find it, return the name
    cleaned_up_name(name)
  end

  def group_names
    Group::NAMES
  end

  def cleaned_up_name(name)
    regex_for_two_and_three_chars = /(\b\w{2,3}\b)|(\b\w{2,3}\d)/
    regex_for_longer_acronyms = /\bAENM\b|\bKPMG\b|\bAPAC\b/i

    regex_for_titleize = /\bPty\b|\bLtd\b|\bBus\b|\bInc\b|\bCo\b|\bTel\b|\bVan\b|\bAus\b/i
    regex_for_titleize_2 = /\bWeb\b|\bNow\b|\bNo\b|\bTen\b|Eli lilly\b|\bNew\b|\bJob\b/i
    regex_for_titleize_3 = /\bDot\b|\bRex\b|\bTan\b|\bUmi\b|\bBig\b|\bDr\b/i

    regex_for_downcase = /\bthe\b|\bof\b|\band\b|\bas\b|\bfor\b/i

    name.titleize
        .gsub(regex_for_two_and_three_chars) { |chars| chars.upcase }
        .gsub(regex_for_longer_acronyms) { |chars| chars.upcase }
        .gsub(regex_for_titleize) { |word| word.titleize }
        .gsub(regex_for_titleize_2) { |word| word.titleize }
        .gsub(regex_for_titleize_3) { |word| word.titleize }
        .gsub(regex_for_downcase) { |word| word.downcase }
        .gsub(/^the/) { |word| word.titleize }
        .gsub(/Pty Limited|Pty\. Ltd\./, 'Pty Ltd')
        .strip
  end
end