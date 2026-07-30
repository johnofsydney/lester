class RecordPersonOrGroup
  def self.call(name, mapper: nil, aec_id: nil)
    new(name, mapper:, aec_id:).call
  end

  def call
    return nil unless name

    if person_or_group == 'person'
      People::RecordPerson.call(first_name_last_name, aec_id:)
    else
      Groups::RecordGroup.call(name, mapper:, aec_id:)
    end
  end

  def initialize(name, mapper: nil, aec_id: nil)
    @name = name.strip
    @mapper = mapper
    @aec_id = aec_id
  end

  # Each entry matches a class of company/party/campaign names and returns 'group'.
  # Order does not matter within this list - order only matters relative to the
  # person/couple checks in #person_or_group below.
  GROUP_KEYWORD_REGEXES = [
    /\bHCF\b|\bINPEX\b|\bCMAX\b|\bSDA\b|\bONA\b|\bSPP\b|\bACCI\b|\bACTU\b|\bCEC\b|\bCLP|\bMSD\b|\bUNSW\b|\bAICR\b|\bAFUL\b|\bAGL\b|\bEY\b|\bPESA\b|\bPR\b|\bGHD\b|\bGas\b|\bPty\b|\bKPMG\b|\bRISC\b/i, # acronyms
    /Corporation|Transport|Tax Aid|Outcomes|Lifestyle|active super/i, # company names
    /business|technology|shopping|toyota|\bbank\b|promotions|publications/i,
    /institute|horticultural|cleaning|technologies|centre|strategic|development/i,
    /Services|investments|entertainment|Insurance|Commerce|Network|Schools/i,
    /Public|affairs|nimbin hemp|company|workpac|wren oil|consultants/i,
    /plumbing|division|federal|office|advisory|deloitte touche/i,
    /company|events|commerce|webdrill|private|restaurant|Mining/i,
    /enterprise|lendlease|party|healthcare|agency|team|lawyers|employment/i,
    /national\b|\bbranch\b|\binstitution\b|\bcommunity|compliance|equipment|solutions/i,
    /guide dogs|\bcommunikate\b|\bDirectors\b|Hunter Land|\bTrading\b|Readyco\b|Stockland\b/i,
    /consulting|ministry|family|Lobbying|Personnel|Resources|Compression/i,
    /jewish|workforce|payments|weaponry|xero|xodus|yokogawa|petroleum|strategy|Environmental/i,
    /metal|minerals|department|university|Constituional|\bChurch\b/i,
    /parliament|minerals|department|university|Constituional|\bChurch\b/i,
    /Anniversary|Empowered|Employment|campaign/i, # specific companies
    /\bLib - Fed\b|\bLib - Sa\b|\bLib - Wa\b|\bLib - Vic\b/i, # party names
    /\bLib Fed\b|\bLib Vic\b/i,
    /\bLib-Act\b|\bLib-Fec\b|\bLib-Fed\b|\bLib-Sa\b|\bLib-Tas\b|\bLib-Vic\b|\bLib-Wa\b/i,
    /\bNat - Fed\b|\bNat-Fed\b/i,
    /\bSocialists\b|\bCommittee\b|\bFund\b|\b(Dialogues|Dialogue)\b|\bForum\b/i,
    /\bFor Yes\b|\bFor No\b\bFor The\b/i, # campaign names
    /Constitutional|Empowered|Employment|campaign/i,
    /Anniversary|Empowered|Employment|campaign/i
  ].freeze

  def person_or_group
    return 'person' if name.match?(People::Regexp::PREFIX_TITLES)

    # tom jones and lady gaga
    return 'group' if name.match?(/([a-z]+) [a-z]+ (and) ([a-z]+) ([a-z]+)/i)

    return 'group' if GROUP_KEYWORD_REGEXES.any? { |regex| name.match?(regex) }

    return 'group' if name.match?(/Not A Race/i)
    return 'group' if name.match?(/NIB Health/i)
    return 'group' if name.match?(/Jewish Commitment To A Better World/i)
    return 'group' if name.match?(/Fairfax Matters/i)
    return 'group' if name.match?(/PricewaterhouseCoopers/i)
    return 'group' if name.match?(/\bSpectrum Health\b/i)
    return 'group' if name.match?(/\bGroundswell Giving\b/i)
    return 'group' if name.match?(/\bWestpoint Autos\b/i)
    return 'group' if name.match?(/\bCampact E\.V\./i)
    return 'group' if name.match?(/Corrs Chambers Westgarth/i)
    return 'group' if name.match?(/Democratic Labour Party/i)
    return 'group' if name.match?(/One Nation/i)
    return 'group' if name.match?(/Kim For Canberra/i)
    return 'group' if name.match?(/Get Up|Getup/i)
    return 'group' if name.match?(/ALP-|ALP -|Alp Bruce Fea/i)
    return 'group' if name.match?(/\bGrn\b/i)
    return 'group' if name.match?(/^Kap$\b/i)
    return 'group' if name.match?(/\bWa-Alp\b/i)
    return 'group' if name.match?(/\LNP-Fed\b/i)
    return 'group' if name.match?(/ACP-VIC/i)
    return 'group' if name.match?(/\bThe Nationals\b/i)
    return 'group' if name.match?(/Nationals (ACT|NT|SA|TAS)/i)
    return 'group' if name.match?(/Independent/i)
    return 'group' if name.match?(/Develco|Ecovis Clark Jacobs|Rapidplas|Rendition Homes/i)
    return 'person' if name.match?(/(?:MP|OAM|AO)$/)  # Check for individuals with MP or OAM
    return 'person' if name.match?(/\bMP\b|\bDr\b/)  # Check for individuals with MP or OAM
    return 'group' if name.match?(/(limited|incorporated|ltd|government|associat|management|group|trust)/i)  # Check for company names
    return 'group' if name.match?(/(australia|management|capital|windfarm|engineering|energy)/i)  # Check for company names
    return 'group' if name.match?(/(guild|foundation|trust|retail|council|union|club|alliance)/i)  # Check for company names
    return 'group' if name.match?(/(new south wales|queensland|state|tasmania|south|northern|territory|western)/i)  # Check for states names
    return 'group' if name.match?(/\b(nsw|n\.s\.w|qld|s\.a\.|n\.t\.|w\.a\.)\b/i)  # Check for states abbreviations
    return 'group' if name.match?(/( pl$|t\/as|trading as| p\/l)/i)  # Check for company endings
    return 'group' if name.match?(/&|\(/)  # Check for entries with ampersands (considered as companies)
    return 'group' if name.match?(/\d/)  # Check for entries with numbers (considered as companies)
    return 'group' if name.include?('+')  # Check for entries with signs (considered as companies)
    return 'couple' if name.include?(' and ')  # Check for couples
    return 'person' if name.match?(/^[A-Z][a-z]+, [A-Z][a-z]+$/)  # Check for names in the format "Lastname, Firstname"
    return 'group' if name.match?(/The .+/)

    'person' # default
  end

  private

  attr_reader :name, :mapper, :aec_id

  def first_name_last_name
    # handle last_name, first_name if in that format
    name.include?(',') ? name.split(',').reverse.join(' ') : name
  end
end
