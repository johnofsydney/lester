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
    return 'group' if name.match?(/(PricewaterhouseCoopers|MSD)/)
    return 'person' if name.match?(/(?:MP|OAM|AO)$/)  # Check for individuals with MP or OAM
    return 'group' if name.match?(/(limited|incorporated|ltd|government|associat|management|group|trust)/i)  # Check for company names
    return 'group' if name.match?(/(australia|management|capital|windfarm|engineering|energy)/i)  # Check for company names
    return 'group' if name.match?(/(guild|foundation|trust|retail|council|union|club|alliance)/i)  # Check for company names
    return 'group' if name.match?(/(nsw|queensland|state|tasmania|south|northern|territory|western)/i)  # Check for states names
    return 'group' if name.match?(/(n\.s\.w|qld|s\.a\.|n\.t\.|w\.a\.)/i)  # Check for states abbreviations
    return 'group' if name.match?(/( pl$|t\/as|trading as| p\/l)/i)  # Check for company endings
    return 'goup' if name.match?(/[&]/)  # Check for entries with hyphens or ampersands (considered as companies)
    return 'goup' if name.match?(/\d/)  # Check for entries with numbers (considered as companies)
    return 'couple' if name.match(/ and /)  # Check for couples
    return 'person' if name.match?(/^[A-Z][a-z]+, [A-Z][a-z]+$/)  # Check for names in the format "Lastname, Firstname"

    'person' # default
  end

  def first_name_last_name
    name.split(',').reverse.join(' ')
  end
end


