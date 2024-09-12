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
    regex_for_removal_honours = /\bOAM\b|\bAO\b|\bAM\b|\bCSC\b|\bCBE\b/i
    regex_for_removal_titles = /\bQC\b|\bProf\b|\bDr\b/i
    regex_for_removal_normal_titles = /\bMr\b|\bMs\b|\bMs\b|\bMiss\b/i

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

    name.gsub(regex_for_removal_elected, '')
        .gsub(regex_for_removal_honours, '')
        .gsub(regex_for_removal_titles, '')
        .gsub(regex_for_removal_normal_titles, '')
        .strip
  end
end
