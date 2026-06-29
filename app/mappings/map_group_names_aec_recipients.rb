class MapGroupNamesAecRecipients < MapGroupNamesBase
  def call(name)
    map_or_return_name(name)
  end

  def map_or_return_name(name)
    raise 'Name is required' if name.blank?

    name = name.gsub(/\s+/, ' ').strip

    return 'Liberal Democratic Party' if name.match?(/\bLiberal.+Democrat/i)
    return 'Shooters, Fishers and Farmers Party' if name.match?(/Shooters, Fishers and Farmers/i)
    return 'Citizens Party' if name.match?(/Citizens Party|\bCEC\b/i)
    return 'Sustainable Australia Party' if name.match?(/Sustainable Australia/i)
    return 'Centre Alliance' if name.match?(/Centre Alliance/i)
    return 'The Local Party of Australia' if name.match?(/The Local Party of Australia/i)
    return 'Katter Australia Party' if name.match?(/(Katter.+Australia|\bKAP\b)/i)
    return 'Australian Conservatives' if name.match?(/Australian Conservatives/i)
    return 'Federal Independents' if name.match?(/Independent Fed/i)
    return 'Waringah Independents' if name.match?(/(Warringah|Waringah).+(independent|Independant)/i)
    return 'Lambie Network' if name.match?(/\bLambie\b/i)
    return 'United Australia Party' if name.match?(/United Australia (Party|Federal)/i)
    return "Pauline Hanson's One Nation" if name.match?(/Pauline Hanson|\bOne Nation\b/i)

    # specific exceptions
    return group_names.liberals.federal if /Liberal Party.+Menzies Research Centre/i.match?(name)
    return group_names.labor.federal if /The Australian Labour Party National Secretar/i.match?(name)
    return group_names.labor.federal if /ALP National \(ALP-FED\)/i.match?(name)
    return group_names.labor.federal if /Australian Labour Party/i.match?(name)
    return group_names.labor.federal if /Australian Federal Labor Party/i.match?(name)

    # Liberal National Party (QLD) and Country Liberal Party (NT)
    return group_names.liberals.qld if /(Liberal National Party|LNP).+(QLD|Queensland)/i.match?(name)
    return group_names.liberals.federal if /Liberal National Party/i.match?(name)
    return group_names.liberals.federal if /Liberal National Fed/i.match?(name)
    return group_names.liberals.nt if /Country Liberal.+(NT|N\.T\.|Northern)/i.match?(name)

    # National Party
    return group_names.nationals.nsw if /(National Party).+(New South Wales|NSW|N\.S\.W\.)/i.match?(name)
    return group_names.nationals.wa if /(National Party).+(Western Australia|WA|W\.A\.)/i.match?(name)
    return group_names.nationals.tas if /National Tasmania/i.match?(name)
    return group_names.nationals.vic if /(National Party).+Vic/i.match?(name)
    return group_names.nationals.federal if /National Party.+Fed/i.match?(name)
    return group_names.nationals.federal if /The Nationals.+Fed/i.match?(name)
    return group_names.nationals.federal if /Nationals.+Fed/i.match?(name)
    return group_names.nationals.federal if /NAT-FED/i.match?(name)
    return group_names.nationals.federal if /NAT FED/i.match?(name)
    return group_names.nationals.federal if /National Party of Australia/i.match?(name)
    return group_names.nationals.federal if /Nat Fed/i.match?(name)
    return group_names.nationals.federal if /National Party/i.match?(name)
    return group_names.nationals.federal if /National Federal/i.match?(name)

    # Liberals, must come after Liberal Democrats
    return group_names.liberals.nsw if /Lib.+(New South Wales|NSW|N\.S\.W\.)/i.match?(name)
    return group_names.liberals.vic if /Lib.+VIC/i.match?(name)
    return group_names.liberals.qld if /Lib.+(QLD|Queensland)/i.match?(name)
    return group_names.liberals.sa if /Lib.+(South Australia|SA|S\.A\.)/i.match?(name)
    return group_names.liberals.nt if /Lib.+(Northern Territory|NT|N\.T\.)/i.match?(name)
    return group_names.liberals.nt if /Clp-Nt/i.match?(name)
    return group_names.liberals.wa if /Lib.+(Western Australia|Western Australia|WA|W\.A\.)/i.match?(name)
    return group_names.liberals.wa if /Liberal Party w\.A.+Division/i.match?(name)
    return group_names.liberals.tas if /Lib.+TAS/i.match?(name)
    return group_names.liberals.act if /Lib.+(ACT|Australian Capital Territory)/i.match?(name)
    return group_names.liberals.federal if /Lib.+(Fed|FEC)/i.match?(name)
    return group_names.liberals.federal if /Lib.+Australia/i.match?(name)
    return group_names.liberals.nsw if /Liberal Party Avalon/i.match?(name)
    return group_names.liberals.federal if /Liberal Party Of Aus/i.match?(name)
    return group_names.liberals.federal if /Australian Federal Liberal Party/i.match?(name)

    # Greens
    return group_names.greens.nsw if /((Greens|GRN).+(New South Wales|NSW|N\.S\.W)|(New South Wales|New South Wales|NSW|N\.S\.W\.).+(Greens|GRN))/i.match?(name)
    return group_names.greens.vic if /((Greens|GRN).+VIC|VIC.+(Greens|GRN))/i.match?(name)
    return group_names.greens.qld if /((Greens|GRN).+(QLD|Queensland)|(QLD|Queensland).+(Greens|GRN))/i.match?(name)
    return group_names.greens.sa if /((Greens|GRN).+(SA|S\.A\.|South Australia)|(SA|S\.A\.|South Australia).+(Greens|GRN))/i.match?(name)
    return group_names.greens.nt if /((Greens|GRN).+(NT|N\.T\.|Northern Territory)|(NT|N\.T\.|Northern Territory).+(Greens|GRN))/i.match?(name)
    return group_names.greens.wa if /((Greens|GRN).+(Western Australia|WA|W\.A\.)|(Western Australia|WA|W\.A\.).+(Greens|GRN))/i.match?(name)
    return group_names.greens.tas if /((Greens|GRN).+TAS|TAS.+(Greens|GRN))/i.match?(name)
    return group_names.greens.act if /((Greens|GRN).+ACT|ACT.+(Greens|GRN))/i.match?(name)
    return group_names.greens.federal if /((Greens|GRN).+Fed|Australian (Greens|GRN))/i.match?(name)

    # Labor
    return group_names.labor.nsw if /(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(New South Wales|NSW|N\.S\.W\.)/i.match?(name)
    return group_names.labor.qld if /(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(QLD|Queensland)/i.match?(name)
    return group_names.labor.sa if /(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(SA|S\.A\.|South Australia)/i.match?(name)
    return group_names.labor.vic if /(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(VIC|Victoria)/i.match?(name)
    return group_names.labor.act if /(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(ACT|Australian Capital Territory)/i.match?(name)
    return group_names.labor.nt if /(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(NT|N\.T\.|Northern Territory)/i.match?(name)
    return group_names.labor.wa if /(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(Western Australia|WA|W\.A\.|Western Australia)/i.match?(name)
    return group_names.labor.tas if /(ALP|CLP|Australian (Labor|Labour)|Country (Labor|Labour)).+(Tas)/i.match?(name)
    return group_names.labor.nsw if /Labor.+(New South Wales|NSW)/i.match?(name)
    return group_names.labor.qld if name.match?(/Labor.+(Queensland|QLD)/i)
    return group_names.labor.sa if name.match?(/Labor.+(South Australia|SA)/i)
    return group_names.labor.vic if name.match?(/Labor.+(Victoria|Vic)/i)
    return group_names.labor.wa if name.match?(/Labor.+(Western Australia|WA)/i)
    return group_names.labor.wa if name.match?(/WA ALP/i) # WA ALP
    return group_names.labor.tas if name.match?(/Labor.+(Tasmania|Tas)/i)
    return group_names.labor.act if name.match?(/Labor.+(Australian Capital Territory|ACT)/i)
    return group_names.labor.nt if name.match?(/Labor.+(Northern Territory|NT)/i)
    return group_names.labor.federal if name.match?(/Labor.+Fed/i)
    return group_names.labor.tas if /Tasmanian.+Labor/i.match?(name)
    return group_names.labor.federal if name.match?(/Country Labor Party|CLP/i)
    return group_names.labor.federal if name.match?(/Australian Labor Party \(Alp\)/i)
    return group_names.labor.federal if name.match?(/Alp National Secretaria/i)
    return group_names.labor.federal if name.match?(/Alp.+Labor Business Forum/i)
    return group_names.labor.federal if name.match?(/Alp.+Fed/i)
    return group_names.labor.federal if name.match?(/Australian Labor Party/i)
    return group_names.labor.federal if name.match?(/ALP Nat/i)
    return group_names.labor.federal if name.match?(/ALP-Nat/i)
    return group_names.labor.federal if name.match?(/ALP Bruce Fea/i)
    return group_names.labor.federal if name.match?(/Australia Labor Party (ALP)/i)
    return group_names.labor.federal if name.match?(/Australia Labor Party/i)
    return group_names.labor.vic if name.match?(/Alp Vic Branch/i)

    # Can't find it, return the name
    cleaned_up_name(name)
  end

  def group_names
    Group::NAMES
  end
end
