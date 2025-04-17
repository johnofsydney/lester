class RecordPersonOrGroup
  def self.call(name)
    new(name).call
  end

  def call
    return nil unless name

    if person_or_group == 'person'
      RecordPerson.call(first_name_last_name)
    elsif person_or_group == 'group'
      RecordGroup.call(name)
    elsif person_or_group == 'couple'
      RecordGroup.call(name)
      # TODO: create memberships for each person in the couple
    else
      RecordGroup.call(name)
    end
  end



  def initialize(name)
    @name = name.strip
  end

  def person_or_group
    regex_for_3_or_4_capitals = /\bHCF\b|\bINPEX\b|\bCMAX\b|\bSDA\b|\bONA\b|\bSPP\b|\bACCI\b|\bACTU\b|\bCEC\b|\bCLP|\bMSD\b|\bUNSW\b|\bAICR\b|\bAFUL\b|\bAGL\b|\bEY\b|\bPESA\b|\bPR\b|\bGHD\b|\bGas\b|\bPty\b|\bKPMG\b|\bRISC\b/i

    regex_for_company_words_1 = /Corporation|Transport|Tax Aid|Outcomes|Lifestyle|active super/i
    regex_for_company_words_2 = /business|technology|shopping|toyota|\bbank\b|promotions|publications/i
    regex_for_company_words_3 = /institute|horticultural|cleaning|technologies|centre|strategic|development/i
    regex_for_company_words_4 = /Services|investments|entertainment|Insurance|Commerce|Network|Schools/i
    regex_for_company_words_5 = /Public|affairs|nimbin hemp|company|workpac|wren oil|consultants/i
    regex_for_company_words_6 = /plumbing|division|federal|office|advisory|deloitte touche/i
    regex_for_company_words_7 = /company|events|commerce|webdrill|private|restaurant|Mining/i
    regex_for_company_words_8 = /enterprise|lendlease|party|healthcare|agency|team|lawyers|employment/i
    regex_for_company_words_9 = /national\b|\bbranch\b|\binstitution\b|\bcommunity|compliance|equipment|solutions/i
    regex_for_company_words_10 = /guide dogs|\bcommunikate\b|\bDirectors\b|Hunter Land|\bTrading\b|Readyco\b|Stockland\b/i
    regex_for_company_words_11 = /consulting|ministry|family|Lobbying|Personnel|Resources|Compression/i
    regex_for_company_words_12 = /jewish|workforce|payments|weaponry|xero|xodus|yokogawa|petroleum|strategy|Environmental/i
    regex_for_company_words_13 = /metal|minerals|department|university|Constituional|\bChurch\b/i
    regex_for_company_words_13 = /parliament|minerals|department|university|Constituional|\bChurch\b/i

    regex_for_party_words_1 = /\bLib - Fed\b|\bLib - Sa\b|\bLib - Wa\b|\bLib - Vic\b/i
    regex_for_party_words_2 = /\bLib Fed\b|\bLib Vic\b/i
    regex_for_party_words_3 = /\bLib-Act\b|\bLib-Fec\b|\bLib-Fed\b|\bLib-Sa\b|\bLib-Tas\b|\bLib-Vic\b|\bLib-Wa\b/i
    regex_for_party_words_4 = /\bNat - Fed\b|\bNat-Fed\b/i
    regex_for_party_words_5 = /\bSocialists\b|\bCommittee\b|\bFund\b|\b(Dialogues|Dialogue)\b|\bForum\b/i

    regex_for_campaign_words_1 = /\bFor Yes\b|\bFor No\b\bFor The\b/i
    regex_for_campaign_words_2 = /Constitutional|Empowered|Employment|campaign/i
    regex_for_campaign_words_3 = /Anniversary|Empowered|Employment|campaign/i

    regex_for_specific_companies_1 = /Anniversary|Empowered|Employment|campaign/i

    return 'group' if name.match?(regex_for_3_or_4_capitals)  # Check for acronyms
    return 'group' if name.match?(regex_for_company_words_1)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_2)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_3)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_4)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_5)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_6)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_7)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_8)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_9)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_10)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_11)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_12)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_13)  # Check for company names

    return 'group' if name.match?(regex_for_party_words_1)  # Check for party related names
    return 'group' if name.match?(regex_for_party_words_2)  # Check for party related names
    return 'group' if name.match?(regex_for_party_words_3)  # Check for party related names
    return 'group' if name.match?(regex_for_party_words_4)  # Check for party related names
    return 'group' if name.match?(regex_for_party_words_5)  # Check for party related names

    return 'group' if name.match?(regex_for_campaign_words_1)  # Check for campaign related names
    return 'group' if name.match?(regex_for_campaign_words_2)  # Check for campaign related names
    return 'group' if name.match?(regex_for_campaign_words_3)  # Check for campaign related names

    return 'group' if name.match?(/Not A Race/i)
    return 'group' if name.match?(/NIB Health/i)
    return 'group' if name.match?(/Jewish Commitment To A Better World/i)
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
    return 'group' if name.match?(/\bKap\b/i)
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

  attr_reader :name

  def first_name_last_name
    # handle last_name, first_name if in that format
    name.include?(',') ? name.split(',').reverse.join(' ') : name
  end
end


