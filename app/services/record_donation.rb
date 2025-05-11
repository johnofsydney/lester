class RecordDonation
  attr_reader :name

  def initialize(name)
    @name = name.strip
  end

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
    end
  end

  def person_or_group
    regex_for_3_or_4_capitals = /HCF|INPEX|CMAX|SDA/
    regex_for_company_words_1 = /Corporation|Transport|Tax Aid|Outcomes|Lifestyle/i
    regex_for_company_words_2 = /business|technology|shopping|toyota|bank|promotions|publications/i
    regex_for_company_words_3 = /institute|horticultural|cleaning|technologies|centre/i
    regex_for_company_words_4 = /Services|investments|entertainment|Insurance|Commerce/i
    regex_for_company_words_5 = /Public|affairs|nimbin hemp|company|workpac|wren oil/i
    regex_for_company_words_6 = /plumbing|division|federal|office|advisory|deloitte touche/i
    regex_for_company_words_7 = /company|events|commerce|webdrill|private|restaurant/i

    return 'group' if name.match?(regex_for_3_or_4_capitals)  # Check for acronyms
    return 'group' if name.match?(regex_for_company_words_1)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_2)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_3)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_4)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_5)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_6)  # Check for company names
    return 'group' if name.match?(regex_for_company_words_7)  # Check for company names

    return 'group' if name.match?(/(PricewaterhouseCoopers|MSD)/)
    return 'person' if name.match?(/(?:MP|OAM|AO)$/)  # Check for individuals with MP or OAM
    return 'person' if name.match?(/\bMP\b|\bDr\b/)  # Check for individuals with MP or OAM
    return 'group' if name.match?(/(limited|incorporated|ltd|government|associat|management|group|trust)/i)  # Check for company names
    return 'group' if name.match?(/(australia|management|capital|windfarm|engineering|energy)/i)  # Check for company names
    return 'group' if name.match?(/(guild|foundation|trust|retail|council|union|club|alliance)/i)  # Check for company names
    return 'group' if name.match?(/(nsw|queensland|state|tasmania|south|northern|territory|western)/i)  # Check for states names
    return 'group' if name.match?(/(n\.s\.w|qld|s\.a\.|n\.t\.|w\.a\.)/i)  # Check for states abbreviations
    return 'group' if name.match?(/( pl$|t\/as|trading as| p\/l)/i)  # Check for company endings
    return 'goup' if name.match?(/[&]/)  # Check for entries with hyphens or ampersands (considered as companies)
    return 'goup' if name.match?(/\d/)  # Check for entries with numbers (considered as companies)
    return 'couple' if name.include?(' and ')  # Check for couples
    return 'person' if name.match?(/^[A-Z][a-z]+, [A-Z][a-z]+$/)  # Check for names in the format "Lastname, Firstname"

    'person' # default
  end

  def first_name_last_name
    name.split(',').reverse.join(' ')
  end
end


