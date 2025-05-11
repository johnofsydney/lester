require 'capitalize_names'

class RecordPerson
  attr_reader :name

  def initialize(name)
    @name = cleaned_up_name(name)
  end

  def self.call(name)
    new(name).call
  end

  def call
    Person.find_or_create_by(name:)
  end

  private

  def cleaned_up_name(name)
    regex_for_removal_elected = /\bMP\b|\bSenator\b/i
    regex_for_removal_honours = /\bOAM\b|\bAO\b|\bAM\b|\bCSC\b|\bCBE\b|\bNK\b/i
    regex_for_removal_titles = /\bQC\b|\bKC\b|\bProf\b|\bDr\b|\bSir\b/i
    regex_for_removal_titles_2 = /\bThe (Hon\.\b|Hon\b|Honourable)/i
    regex_for_removal_titles_3 = /^Hon\b|^Hon\.\b/i
    regex_for_removal_normal_titles = /\bMr\b|\bMrs\b|\bMs\b|\bMiss\b/i

    if name.include?(',')
      name = name.split(',').reverse.join(' ')
    end

    name = name.strip
               .gsub(regex_for_removal_elected, '')
               .gsub(regex_for_removal_honours, '')
               .gsub(regex_for_removal_titles, '')
               .gsub(regex_for_removal_titles_2, '')
               .gsub(regex_for_removal_titles_3, '')
               .gsub(regex_for_removal_normal_titles, '')
               .delete('.')
               .strip

    name = CapitalizeNames.capitalize(name)

    # This is temporary, and should be replaced with a name disambiguator
    # TODO: Create a name disambiguator
    return 'David Pocock' if name.match?(/David Pocock/i)
    return 'Nicholas Fairfax' if name.match?(/Nicholas John Fairfax/i)
    return 'Kylea Tink' if name.match?(/Kylea.+Tink/i)
    return 'Allegra Spender' if name.match?(/Allegra.+Spender/i)
    return 'Brian Mitchell' if name.match?(/Brian.+Mitchell/i)
    return 'Carina Garland' if name.match?(/Carina.+Garland/i)
    return 'Monique Ryan' if name.match?(/Monique.+Ryan/i)
    return 'Kate Chaney' if name.match?(/Katherine.+Chaney/i)
    return 'Sophie Scamps' if name.match?(/Sophie.+Scamps/i)
    return 'Andrew Wilkie' if name.match?(/Andrew.+Wilkie/i)
    return 'Tony Windsor' if name.match?(/Antony Harold Curties Windsor/i)
    return 'Bob Katter' if name.match?(/Robert.+Katter/i)
    return 'Malcolm Turnbull' if name.match?(/Malcolm.+Turnbull/i)
    return 'Helen Haines' if name.match?(/Helen.+Haines/i)
    return 'Greg Cheesman' if name.match?(/Greg.+Cheesman/i)
    return 'Jacinta Nampijinpa Price' if name.match?(/Jacinta.+Price/i)
    return 'Kerryn Phelps' if name.match?(/Kerryn.+Phelps/i)
    return 'Mike Cannon Brookes' if name.match?(/(Mike|Michael) Cannon.+Brookes/i)
    return 'Fraser Anning' if name.match?(/Fraser.+Anning/i)
    return 'Zoe Daniel' if name.match?(/Zoe Daniel/i)
    return 'Catriona Faehrmann' if name.match?(/Catriona Faehrmann|Cate Faehrmann/i)
    return 'Jamie Parker' if name.match?(/Jamie Parker|Jamie Thomas Parker/i)
    return 'Kerry Chikarovski' if name.match?(/Kerry Chikarovski|Kerry Anne Chikarovski/i)
    return 'Kevin Rudd' if name.match?(/Kevin Rudd|Kevin Michael Rudd/i)
    return 'Kristina Keneally' if name.match?(/Kristina Keneally|Kristina Kerscher Keneally/i)
    return 'Linda Burney' if name.match?(/Linda Burney|Linda Jean Burney/i)
    return 'Peter Collins' if name.match?(/Peter Collins|Peter Edward James Collins/i)

    name.strip
  end
end
