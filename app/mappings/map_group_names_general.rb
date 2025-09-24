require 'capitalize_names'

class MapGroupNamesGeneral
  def call(name)
    map_or_return_name(name)
  end

  def map_or_return_name(name)
    raise 'Name is required' if name.blank?

    name = name.gsub(/\s+/, ' ').strip

    return 'Get Up Limited' if name.match?(/(GetUp|Get Up)/i)
    return 'Australian Hotels Association' if name.match?(/Australian Hotels Association/i)
    return 'Advance Australia' if name.match?(/Advance Aus|Advanced Aus|^Advance$/i)
    return "It's Not a Race Limited" if name.match?(/(Not A Race|Note a Race)/i)
    return 'Australian Council of Trade Unions' if name.match?(/\bACTU\b/i)
    return 'Climate 200 Pty Ltd' if name.match?(/(Climate 200|Climate200)/i)
    return 'Australian Chamber of Commerce and Industry' if name.match?(/Australian Chamber of Commerce and Industry/i)
    return 'Australian Chamber of Commerce and Industry' if name.match?(/Australia Chamber of Commerce and Industry/i)
    return 'Hadley Holdings Pty Ltd' if name.match?(/Hadley Holdings/i)
    return 'University of NSW' if name.match?(/University of (NSW|New South Wales)|UNSW/i)
    return 'Australian Communities Foundation Limited' if name.match?(/Australian Communities Foundation/i)
    return 'Australians for Unity Ltd' if name.match?(/(Australia|Australian|Australians) for Unity|\bAFUL\b/i)
    return 'Australians for Indigenous Constitutional Recognition' if name.match?(/Australians for (Indigenous|Indigneous) (Constitution|Constitutional|Consititutional) (Recognition|Recgonition|Recongition)|\bAICR\b|\b\(aicr\)\b/i)
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
    return 'Gilbert & Tobin' if name.match?(/Gilbert (&|and|And) Tobin/i)
    return 'JMR Management Consultancy Services Pty Ltd' if name.match?(/JMR Management Consultancy/i)

    return 'NIB Health Funds Limited' if name.match?(/NIB Health Funds/i)

    return 'Origin Energy' if name.match?(/Origin Energy/i)
    return 'Pricewaterhousecoopers' if name.match?(/Pricewaterhousecoopers/i)
    return 'CMAX Advisory' if name.match?(/CMAX (Advisory|Communications)/i)
    return 'Corporate Affairs Australia Pty Ltd' if name.match?(/Corporate Affairs (Australia Pty Ltd|Advisory)/i)
    return 'Hawker Britton Pty Ltd' if name.match?(/Hawker Britton.+Pty Ltd/i)
    return 'Pacific Partners Strategic Advocacy Pty Ltd' if name.match?(/Pacific.+Strategic Advocacy Pty Ltd/i)
    return 'Probity International Pty Ltd' if name.match?(/Probity International Pty.+Ltd/i)
    return 'The Pharmacy Guild of Australia' if name.match?(/Pharmacy Guild/i)
    return 'Your Solutions Compounding Pharmacy' if name.match?(/Your Solutions Compounding Pharmacy/i)
    return 'AGL Energy Limited' if name == 'AGL'
    return 'AIA Australia' if name == 'AIA'
    return 'AMP Limited' if name == 'AMP'
    return 'Abbott Medical Australia Pty Ltd' if name == 'Abbott'
    return 'Abbvie Australia' if name.match?(/\bAbbvie\b/i)
    return 'Adecco Australia' if name.include?('Adecco Australia')
    return 'Afterpay Australia Pty Ltd' if name.include?('Afterpay Pty Ltd')
    return 'Agripower Australia Limited' if name.include?('Agripower')
    return 'Amazon Web Services Australia Pty Ltd' if name.match?(/Amazon Web Services Australia|Amazon AWS WEB Services Australia Pty Ltd/i)
    return 'Amazon Web Services Limited' if name.match?(/Amazon Web Services/i)
    return 'Amazon Australia' if name.match?(/\bAmazon\b/i)
    return 'Amgen Australia Pty Ltd' if name.match?(/Amgen Australia/i)
    return 'Ampol Limited' if name.match?(/Ampol (Ltd|Limited)/i)
    return 'Angus Knight Group' if name.match?(/Angus Knight (Group|Pty Ltd|Pty Limited)/i)

    return 'Arafura Rare Earths' if name.match?(/Arafura (Rare Earths|Resources)/i)
    return 'Ausbiotech' if name.match?(/\bAusbiotech\b/i)
    return 'Australian Capital Equity Pty Ltd' if name.match?(%r{\bAustralian Capital Equity (Pty Ltd|P/L)\b}i)
    return 'Australian Computer Society' if name.match?(/\bAustralian Computer Society Incorporated\b/i)
    return 'BP Australia Pty Ltd' if name.match?(/\bBP Australia Pty Ltd\b/i) || name == 'BP Australia'
    return 'Bayer Australia Ltd' if name.match?(/\bBayer Australia (Ltd|Limited)\b/i)
    return 'Beach Energy Limited' if name.match?(/\bBeach Energy\b/i)
    return 'Bowen Coking Coal' if name.match?(/\bBowen Coking Coal\b/i)
    return 'Bus Association of Victoria' if name.match?(/\bBus Association of Victoria\b/i)
    return 'CAE Australia Pty Ltd' if name.match?(/CAE Australia|^CAE$/i)
    return 'CO2CRC' if name.match?(/CO2crc/i)
    return 'Canberra Consulting' if name.match?(/Canberra Consulting/i)
    return 'Careflight' if name.match?(/Careflight/i)
    return 'Chevron Australia Pty Ltd' if name.match?(/Chevron/i)
    return 'Citigroup' if name.match?(/\bCitigroup\b/i)
    return 'Civmec Construction & Engineering Pty Ltd' if name.match?(/\bCivmec Construction.+Engineering\b/i)
    return 'Conocophillips Australia Pty Ltd' if name.match?(/\bConocophillips\b/i)
    return 'Consolidated Properties Group' if name.match?(/\bConsolidated Properties Group\b/i) || name == 'Consolidated Properties'
    return 'Cooper Energy Ltd' if name.match?(/\bCooper Energy Ltd\b/i) || name == 'Cooper Energy'
    return 'Delaware North' if name.match?(/\bDelaware North\b/i)
    return 'Dell Australia Pty Ltd' if name.match?(/\bDell (Australia|Technologies)\b/i)
    return 'Diageo Australia Limited' if name.match?(/\bDiageo Australia\b/i)
    return 'Droneshield Limited' if name.match?(/\bDroneshield\b/i)
    return 'Echostar Global Australia Pty Ltd' if name.match?(/\bEchostar\b/i)
    return 'Edwards Lifesciences Pty Ltd' if name.match?(/\bEdwards Life(sciences)?\b/i)

    return 'Elbit Systems of Australia P/L' if name.match?(/\bElbit Systems.+Australia/i)
    return 'Electro Optic Systems Pty Ltd' if name.match?(/\bElectro Optic Systems/i)
    return 'Eli Lilly Australia Pty Ltd' if name.match?(/\bEli Lilly Australia\b/i) || name == 'Eli Lilly'
    return 'Environmental Defense Fund' if name.match?(/\bEnvironmental Defense Fund/i)
    return 'Equinor Australia' if name.match?(/\bEquinor Australia\b/i) || name == 'Equinor'
    return 'Ernst & Young' if name.match?(/\bErnst .+ Young\b/i)
    return 'Eusa Pharma (Australia) Pty Ltd' if name.match?(/\bEusa Pharma \(Australia\) Pty Ltd\b/i) || name == 'Eusa Pharma'
    return 'Expedia Australia Pty Ltd' if name.match?(/\bExpedia Australia Pty Ltd\b/i) || name == 'Expedia'
    return 'Field and Game Australia' if name.match?(/\bField and Game Australia\b/i)
    return 'Football Australia' if name.match?(/\bFootball Australia Limited\b/i) || name == 'Football Australia'
    return 'Fortem Australia Limited' if name.match?(/\bFortem Australia Limited\b/i) || name == 'Fortem Australia'
    return 'Free TV Australia Limited' if name.match?(/\b(Free TV|FreeTV) Australia\b/i)

    return 'Frisk - Search Pty Ltd' if name.match?(/\bFrisk.*Search\b/i)
    return 'From the Fields Pharmaceuticals Australia Pty Ltd' if name.match?(/\bFrom The Fields\b/i)
    return 'Fugro Australia Pty Ltd' if name.match?(/\bFugro Australia\b/i) || name == 'Fugro'
    return 'GB Energy Holdings Pty Ltd' if name.match?(/\bGB Energy Holdings\b/i) || name == 'GB Energy'
    return 'Gascoyne Gateway Limited' if name.match?(/\bGascoyne Gateway (Limited|Ltd)\b/i)
    return 'Gedeon Richter Australia Pty Ltd' if name.match?(/\bGedeon Richter Australia\b/i)
    return 'Gilmour Space Technologies Pty Ltd' if name.match?(/\bGilmour Space Technologies\b/i)
    return 'Gippsland Critical Minerals' if name.match?(/\bGippsland Critical Minerals\b/i)
    return 'Glengarry Advisory Pty Ltd' if name.match?(/\bGlengarry Advisory\b/i)
    return 'Golf Australia Limited' if name.match?(/\bGolf Australia (Limited|Ltd)\b/i)
    return 'Google Australia Pty Ltd' if name.match?(/\bGoogle Australia\b/i)
    return 'Group of 100' if name.match?(/\bGroup of 100\b/i)
    return 'Gulanga Group' if name.match?(/\bGulanga Group\b/i)
    return 'Heartland Solutions Group' if name.match?(/\bHeartland Solutions Group\b/i)
    return 'Holmes Institute' if name.match?(/\bHolmes Institute\b/i)
    return 'Holmwood Highgate Pty Ltd' if name.match?(/\bHolmwood Highgate\b/i)

    return 'Idemitsu Australia Pty Ltd' if name.match?(/\bIdemitsu Australia\b/i)
    return 'Inghams Group Limited' if name.match?(/\bInghams Group (Limited|LTD)\b/i) || name == 'Inghams'
    return 'Insurance Council of Australia' if name.match?(/\bInsurance Council of Australia\b/i)
    return 'Intech Strategies P/L' if name.match?(/\bIntech Strategies\b/i)
    return 'Ipsen Pty Ltd' if name.match?(/\bIpsen Pty Ltd\b/i) || name == 'Ipsen'
    return 'Israel Aerospace Industries Limited' if name.match?(/\bIsrael Aerospace Industries (Limited|Ltd)\b/i)
    return 'JERA Australia Pty Ltd' if name.match?(/\bJERA Australia\b/i) || name == 'Jera'
    return 'Jellinbah Group' if name.match?(/\bJellinbah Group\b/i)
    return 'Johnson & Johnson Medical' if name.match?(/\bJohnson (&|And) Johnson Medical\b/i)
    return 'Johnson & Johnson Pty Ltd' if name.match?(/\bJohnson (&|And) Johnson\b/i)
    return 'KPMG Australia' if name.match?(/\bKPMG Australia\b/i) || name == 'KPMG'
    return 'Kimberly-Clark Australia Pty Ltd' if name.match?(/\bKimberly-*Clark Australia\b/i) || name.match?(/\bKimberlyClark\b/i)
    return 'L3 Harris Technologies' if name.match?(/(L3 Harris|L3Harris) Technologies/i)
    return 'Lendlease Australia Pty Ltd' if name.match?(/Lendlease.+Australia/i) || name.match?(/Lendlease Pty Ltd/i)
    return 'Lion Pty Ltd' if name.downcase == 'lion'
    return 'Lockheed Martin Australia Pty Ltd' if name.match?(/Lockheed Martin Australia/i)

    return 'Matrix Composites & Engineering' if name.match?(/Matrix Composites.+Engineering/i)
    return 'Merck Healthcare' if name.match?(/Merck Healthcare/i)
    return 'Metallicum Minerals Corporation' if name.match?(/Metallicum Minerals Corporation/i)
    return 'National Retail Association Limited' if name.match?(/National Retail Association/i)
    return 'Nestle Australia' if name.match?(/(Nestle|Nestlé) Australia/i)
    return 'Netapp Pty Ltd' if name.match?(/Netapp Pty Ltd/i) || name == 'Netapp'
    return 'Novo Nordisk Pharmaceuticals Pty Ltd' if name.match?(/Novo Nordisk Pharmaceuticals/i)
    return 'Orion Sovereign Group Pty Ltd' if name.match?(/Orion Sovereign Group/i)
    return 'PainAustralia Limited' if name.match?(/painaustralia/i)
    return 'Paintback Limited' if name.match?(/paintback/i)
    return 'Pathology Technology Australia' if name.match?(/Pathology Technology Australia/i)
    return 'Pembroke Resources Pty Ltd' if name.match?(/Pembroke Resources( Pty Ltd)*/i)

    return 'Penten Pty Ltd' if name.match?(/Penten Pty Ltd/i) || name == 'Penten'
    return 'Playgroups Australia' if name.match?(/Playgroups Australia/i)
    return 'Pratt Holdings Pty Ltd' if name.match?(/Pratt Holdings/i)
    return 'RES Australia Pty Ltd' if name.match?(/RES Australia( Pty Ltd)*/i)
    return 'RZ Resources Limited' if name.match?(/RZ Resources (Limited|Ltd)/i)
    return 'Ramsay Health Care Limited' if name.match?(/Ramsay Health Care/i)
    return 'Rare Cancers Australia' if name.match?(/Rare Cancers Australia/i)
    return 'Ryman Healthcare (Australia) Pty Ltd' if name.match?(/Ryman Healthcare.+Australia/i) || name.downcase == 'ryman healthcare'
    return 'SA Milgate and Associates Pty Ltd' if name.match?(/SA Milgate and Associates/i)
    return 'ST John of GOD Healthcare' if name.match?(/ST John of GOD (Healthcare|Health Care)/i)
    return 'Saab Australia Pty Ltd' if name.match?(/Saab Australia Pty Ltd/i) || name.downcase == 'saab'
    return 'Settlement Services International' if name.match?(/Settlement Services International/i)
    return "Shop Distributive & Allied Employees Association - National'" if name.match?(/Shop.+Distributive (&|and) Allied Employees.+Association.+(National|nat branch)/i)
    return "Shop Distributive & Allied Employees Association - National'" if name.match?(/Shop.+Allied Employees.+Association.+National/i)
    return 'SMEC Australia Pty Ltd' if name.match?(/Smec Australia/i)
    return 'Sovori Pty Ltd ATF the Sovori Trust' if name.match?(/Sovori Pty Ltd/i)

    return 'Space Machines Company' if name.match?(/Space Machines Company/i)
    return 'Speedcast Australia Pty Ltd' if name.match?(/Speedcast Australia Pty Ltd/i) || name == 'Speedcast'
    return 'Spirits & Cocktails Australia' if name.match?(/Spirits (&|and) Cocktails Australia/i)
    return 'Springfield City Group' if name.match?(/Springfield City Group/i)
    return 'Standbyu Foundation' if name.match?(/Standbyu Foundation/i)
    return 'Stryker Australia Pty Ltd' if name.match?(/Stryker Australia Pty Ltd/i) || name.downcase == 'stryker'
    return 'Strzelecki Holdings Pty Ltd' if name.match?(/Strzelecki (Holdings|Holding) Pty Ltd/i)
    return 'Sumitomo Corporation' if name.match?(/(Sumitomo|Sumitom) Corporation/i)
    return 'Ted Noffs Foundation' if name.match?(/TED Noffs Foundation/i)
    return 'Tellus Holdings Ltd' if name.match?(/Tellus Holdings/i)
    return 'Telstra Corporation' if name.match?(/Telstra Corporation/i) || name.downcase == 'telstra'
    return 'The Alannah & Madeline Foundation' if name.match?(/The Alannah (&|and) Madeline Foundation/i)
    return 'The Premier Communications Group' if name.match?(/The Premier Communications Group/i)
    return 'The Union Education Foundation' if name.match?(/The Union Education Foundation/i)
    return 'Trademark Group of Companies' if name.match?(/Trademark Group of Companies/i)
    return 'Trafigura' if name.match?(/Trafigura Pte Ltd/i) || name.downcase == 'trafigura'
    return 'Tronox Limited' if name.match?(/Tronox (Limited|Ltd)/i)

    return 'UCB Australia Pty Ltd' if name.match?(/UCB Australia (Pty Ltd|Proprietary Limited)/i)
    return 'Uber Australia Pty Ltd' if name.match?(/Uber Australia Pty Ltd/i) || name.downcase == 'uber'
    return 'Van Dairy Ltd' if name.match?(/Van Dairy Ltd/i) || name.match?(/\bvanmilk\b/)
    return 'Varley Rafael Australia' if name.match?(/Varley Rafael Australia/i) || name.downcase == 'varley rafael'
    return 'Verbrec Ltd' if name.match?(/Verbrec (Ltd|Limited)/i) || name.downcase == 'verbrec'
    return 'Verdant Minerals' if name.match?(/Verdant Minerals/i)
    return 'Vertex Pharmaceuticals Australia Pty Ltd' if name.match?(/Vertex Pharmaceuticals.+Australia/i)
    return 'Victorian Hydrogen and Ammonia Industries Limited' if name.match?(/Victorian Hydrogen (&|and) Ammonia Industries/i)
    return 'Wesfarmers Limited' if name.match?(/Wesfarmers (Limited|Ltd)/i) || name.downcase == 'wesfarmers'
    return 'Westpac Banking Corporation' if name.match?(/Westpac Banking Corporation/i) || name.downcase == 'westpac'

    return 'Yumbah Aquaculture' if name.match?(/Yumbah Aquaculture/i)
    return 'Clubs Australia' if name.match?(/ClubsAustralia Inc/i)
    return 'Idameneo (No 123) Pty Ltd' if name.match?(/Idameneo.+123/i)
    return 'Schaffer Corporation Limited' if name.match?(/Schaffer Corporation (Limited|Ltd)/i)
    return 'The Union Education Foundation' if name.match?(/Union Education Foundation/i)
    return 'Tamboran Resources Limited' if name.match?(/Tamboran Resources/i)
    return 'Tamboran Resources Limited' if name.match?(/Tamboran Resources/i)
    return 'Paladin Group' if name.match?(/Paladin Group/i)
    return 'Qube Ports' if name.match?(/Qube Ports/i)
    return 'Australian Energy Producers' if name.match?(/\bAPPEA\b|Australian Energy Producers/i)

    # Can't find it, return the name
    cleaned_up_name(name)
  end

  def group_names
    Group::NAMES
  end

  def cleaned_up_name(name)
    regex_for_two_and_three_chars = /(\b\w{2,3}\b)|(\b\w{2,3}\d)/
    regex_for_longer_acronyms_1 = /\bAENM\b|\bKPMG\b|\bAPAC\b|\bACCI\b|\bDBPC\b|\bCEPU\b|\bACDC\b|\bCFMEU\b/i
    regex_for_longer_acronyms_2 = /\bPESA\b|\bRISC\b|\bJERA\b|\bAMPD\b|\bAFTA\b|\bFTTH\b|\bGCFC\b|\bGIMC\b/i
    regex_for_longer_acronyms_3 = /\bCPSU\b|\bSPSF\b|\bCRRC\b|\bCSIROb|\bCTSI\b|\bERGT\b|\bGGBV\b|\bHSBC\b/i
    regex_for_longer_acronyms_4 = /\bCPAC\b/i

    regex_for_titleize = /\bPty\b|\bLtd\b|\bBus\b|\bInc\b|\bCo\b|\bTel\b|\bVan\b|\bAus\b|\bIan\b/i
    regex_for_titleize_2 = /\bMud\b\bWeb\b|\bNow\b|\bNo\b|\bTen\b|Eli lilly\b|\bNew\b|\bJob\b/i
    regex_for_titleize_3 = /\bDot\b|\bRex\b|\bTan\b|\bUmi\b|\bBig\b|\bDr\b|\bGas\b|\bOil\b/i
    regex_for_titleize_4 = /\bTax\b|\bAid\b|\bBay\b|\bTo\b|\bYes\b|\bRed\b|\bOne\b|\bSky\b/i
    regex_for_titleize_5 = /\bAmazon Web Services\b|\bAce Gutters\b|\bMud Guards\b|\bGum Tree\b|\bYe Family\b/i
    regex_for_titleize_6 = /\bRio Tinto\b|\bRed Rocketship\b|\bCar Park\b|\bAir Liquide\b/i
    regex_for_titleize_7 = /\bVictoria\b|\bQueensland\b|\bTasmania\b/i
    regex_for_titleize_8 = /\Air New Zealand\b|\bAir Pacific\b|\bAir Liquide\b|Singapore/i
    regex_for_titleize_9 = /\Be Our Guest\b|\bBlack Dog\b/i
    regex_for_titleize_10 = /\bJoe\b/i

    regex_for_downcase = /\bthe\b|\bof\b|\band\b|\bas\b|\bfor\b|\bis\b/i

    CapitalizeNames.capitalize(name.strip)
                   .gsub(regex_for_two_and_three_chars, &:upcase)
                   .gsub(regex_for_longer_acronyms_1, &:upcase)
                   .gsub(regex_for_longer_acronyms_2, &:upcase)
                   .gsub(regex_for_longer_acronyms_3, &:upcase)
                   .gsub(regex_for_longer_acronyms_4, &:upcase)
                   .gsub(regex_for_titleize, &:titleize)
                   .gsub(regex_for_titleize_2, &:titleize)
                   .gsub(regex_for_titleize_3, &:titleize)
                   .gsub(regex_for_titleize_4, &:titleize)
                   .gsub(regex_for_titleize_5, &:titleize)
                   .gsub(regex_for_titleize_6, &:titleize)
                   .gsub(regex_for_titleize_7, &:titleize)
                   .gsub(regex_for_titleize_8, &:titleize)
                   .gsub(regex_for_titleize_9, &:titleize)
                   .gsub(regex_for_titleize_10, &:titleize)
                   .gsub(regex_for_downcase, &:downcase)
                   .gsub(/^the/, &:titleize)
                   .gsub('australia', &:titleize)
                   .gsub(/Pty Limited|Pty\. Ltd\.|Pty Ltd\./, 'Pty Ltd')
                   .gsub(/PTE\.? Ltd\.?/i, 'Pte Ltd')
                   .gsub('(t/as Clubsnsw)', '(T/As ClubsNSW)')
  end
end