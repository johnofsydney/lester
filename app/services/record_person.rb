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
    regex_for_removal_elected = /\bMP\b|\bSenator\b/
    regex_for_removal_honours = /\bOAM\b|\bAO\b|\bAM\b/
    regex_for_removal_titles = /\bQC\b|\bProf\b|\bDr\b/

    name.gsub(regex_for_removal_elected, '')
        .gsub(regex_for_removal_honours, '')
        .gsub(regex_for_removal_titles, '')
        .strip
  end
end
