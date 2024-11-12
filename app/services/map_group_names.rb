require 'capitalize_names'

class MapGroupNames
  def initialize(name)
    @name = map_or_return_name(name)
  end

  def call
    @name
  end

  def map_or_return_name(name)
    raise 'Name is required' if name.blank?

    name = name.gsub(/\s+/, ' ').strip

    return 'Get Up Limited' if name.match?(/(GetUp|Get Up)/i)
    return 'Australian Hotels Association' if name.match?(/Australian Hotels Association/i)
    return 'Advance Australia' if name.match?(/Advance Aus|Advanced Aus/i)
    return "It's Not a Race Limited" if name.match?(/(Not A Race|Note a Race)/i)
    return 'Australian Council of Trade Unions' if name.match?(/\bACTU\b/i)
    return 'Climate 200 Pty Ltd' if name.match?(/(Climate 200|Climate200)/i)
    return 'Australian Chamber of Commerce and Industry' if name.match?(/Australian Chamber of Commerce and Industry/i)
    return 'Australian Chamber of Commerce and Industry' if name.match?(/Australia Chamber of Commerce and Industry/i)
    return 'Hadley Holdings Pty Ltd' if name.match?(/Hadley Holdings/i)
    return 'University of NSW' if name.match?(/University of (NSW|New South Wales)|UNSW/i)
    return 'Australian Communities Foundation Limited' if name.match?(/Australian Communities Foundation/i)
    return 'Australians for Unity Ltd' if name.match?(/(Australia|Australian|Australians) for Unity|\bAFUL\b/i)
    return 'Australians for Indigenous Consititutional Recognition' if name.match?(/Australians for (Indigenous|Indigneous) (Constitution|Constitutional|Consititutional) (Recognition|Recgonition|Recongition)|\bAICR\b|\b\(aicr\)\b/i)
    return 'Climate Action Network Australia' if name.match?(/Climate Action Network Australia/i)
    return 'Stand UP: Jewish Commitment TO A Better World' if name.match?(/(Tand|Stand) UP: Jewish Commitment TO A Better World/i)
    return 'The Australia Institute' if name.match?(/Australia Institute/i)
    return 'The Dugdale Trust for Women and Girls' if name.match?(/The Dugdale Trust for (Women|Womens) and Girls/i)
    return 'Uphold and Recognise Limited' if name.match?(/Uphold.+Recognise/i)
    return 'Keldoulis Investments Pty Ltd' if name.match?(/Keldoulis Investments/i)
    return 'Turner Components Pty Ltd' if name.match?(/Turner Components/i)
    return 'Glencore Australia' if name.match?(/Glencore Australia/i)
    return 'Whitehaven Coal Limited' if name.match?(/Whitehaven Coal/i)
    return 'Woodside Energy' if name.match?(/Woodside Energy/i)
    return 'Origin Energy' if name.match?(/Origin Energy/i)
    return 'Sentinel Property Group' if name.match?(/Sentinel Property Group/i)
    return 'Chevron Australia Pty Ltd' if name.match?(/Chevron Australia/i)
    return 'Inpex Corporation' if name.match?(/Inpex/i)
    return 'Barton Deakin Pty Ltd' if name.match?(/Barton Deakin/i)
    return 'Mineralogy Pty Ltd' if name.match?(/Mineralogy/i)
    return 'Bluescope Steel Limited' if name.match?(/Bluescope Steel/i)
    return 'Gilbert & Tobin' if name.match?(/Gilbert . Tobin/i)
    return 'JMR Management Consultancy Services Pty Ltd' if name.match?(/JMR Management Consultancy/i)
    return 'NIB Health Funds Limited' if name.match?(/NIB Health Funds/i)
    return 'Origin Energy' if name.match?(/Origin Energy/i)
    return 'Woodside Energy Group Ltd' if name.match?(/Woodside Energy/i)
    return 'Pricewaterhousecoopers' if name.match?(/Pricewaterhousecoopers/i)
    return 'CMAX Advisory' if name.match?(/CMAX (Advisory|Communications)/i)
    return 'Corporate Affairs Australia Pty Ltd' if name.match?(/Corporate Affairs (Australia Pty Ltd|Advisory)/i)
    return 'Hawker Britton Pty Ltd' if name.match?(/Hawker Britton.+Pty Ltd/i)
    return 'Pacific Partners Strategic Advocacy Pty Ltd' if name.match?(/Pacific.+Strategic Advocacy Pty Ltd/i)
    return 'Probity International Pty Ltd' if name.match?(/Probity International Pty.+Ltd/i)


    # https://en.wikipedia.org/wiki/Australian_Energy_Producers
    return 'Australian Energy Producers' if name.match?(/\bAPPEA\b|Australian Energy Producers/i)

    # Independents

    # return 'Kim for Canberra' if name.match?(/Kim for Canberra/i)
    # return 'Helen Haines Campaign' if name.match?(/Helen Haines/i)

    return 'Liberal Democratic Party' if name.match?(/Liberal.+Democrat/i)

    return 'Shooters, Fishers and Farmers Party' if name.match?(/Shooters, Fishers and Farmers/i)
    return 'Citizens Party' if name.match?(/(Citizens Party|CEC)/i)
    return 'Sustainable Australia Party' if name.match?(/Sustainable Australia/i)
    return 'Centre Alliance' if name.match?(/Centre Alliance/i)
    return 'The Local Party of Australia' if name.match?(/The Local Party of Australia/i)
    return 'Katter Australia Party' if name.match?(/(Katter.+Australia|KAP)/i)
    return 'Australian Conservatives' if name.match?(/Australian Conservatives/i)
    return 'Federal Independents' if name.match?(/Independent Fed/i)
    return 'Waringah Independents' if name.match?(/(Warringah|Waringah).+(independent|Independant)/i)
    return 'Lambie Network' if name.match?(/Lambie/i)
    return 'United Australia Party' if name.match?(/United Australia (Party|Federal)/i)
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
    return group_names.nationals.tas if name.match(/National Tasmania/i)
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
    return group_names.liberals.nt if name.match(/Clp-Nt/i)
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

  def cleaned_up_name(name)
    regex_for_two_and_three_chars = /(\b\w{2,3}\b)|(\b\w{2,3}\d)/
    regex_for_longer_acronyms_1 = /\bAENM\b|\bKPMG\b|\bAPAC\b|\bACCI\b|\bDBPC\b|\bCEPU\b|\bACDC\b|\bCFMEU\b/i
    regex_for_longer_acronyms_2 = /\bPESA\b|\bRISC\b|\bJERA\b/i

    regex_for_titleize = /\bPty\b|\bLtd\b|\bBus\b|\bInc\b|\bCo\b|\bTel\b|\bVan\b|\bAus\b|\bIan\b/i
    regex_for_titleize_2 = /\bMud\b\bWeb\b|\bNow\b|\bNo\b|\bTen\b|Eli lilly\b|\bNew\b|\bJob\b/i
    regex_for_titleize_3 = /\bDot\b|\bRex\b|\bTan\b|\bUmi\b|\bBig\b|\bDr\b|\bGas\b|\bOil\b/i
    regex_for_titleize_4 = /\bTax\b|\bAid\b|\bBay\b|\bTo\b|\bYes\b|\bRed\b|\bOne\b|\bSky\b/i
    regex_for_titleize_5 = /\bAmazon Web Services\b|\bAce Gutters\b|\bMud Guards\b|\bGum Tree\b|\bYe Family\b/i
    regex_for_titleize_6 = /\bRio Tinto\b|\bRed Rocketship\b|\bCar Park\b/i
    regex_for_titleize_7 = /\bVictoria\b|\bQueensland\b|\bTasmania\b/i


    regex_for_downcase = /\bthe\b|\bof\b|\band\b|\bas\b|\bfor\b|\bis\b/i

    CapitalizeNames.capitalize(name.strip)
                   .gsub(regex_for_two_and_three_chars) { |chars| chars.upcase }
                   .gsub(regex_for_longer_acronyms_1) { |chars| chars.upcase }
                   .gsub(regex_for_longer_acronyms_2) { |chars| chars.upcase }
                   .gsub(regex_for_titleize) { |word| word.titleize }
                   .gsub(regex_for_titleize_2) { |word| word.titleize }
                   .gsub(regex_for_titleize_3) { |word| word.titleize }
                   .gsub(regex_for_titleize_4) { |word| word.titleize }
                   .gsub(regex_for_titleize_5) { |word| word.titleize }
                   .gsub(regex_for_titleize_6) { |word| word.titleize }
                   .gsub(regex_for_titleize_7) { |word| word.titleize }
                   .gsub(regex_for_downcase) { |word| word.downcase }
                   .gsub(/^the/) { |word| word.titleize }
                   .gsub(/australia/) { |word| word.titleize }
                   .gsub(/Pty Limited|Pty\. Ltd\./, 'Pty Ltd')
                   .gsub('(t/as Clubsnsw)', '(T/As ClubsNSW)')
  end
end