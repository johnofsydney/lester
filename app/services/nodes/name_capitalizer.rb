require 'capitalize_names'

class Nodes::NameCapitalizer
  PEOPLE_NAMES = %w[Greg Paul John Pete Jan Troy Lucy Marc Sep Mark Kate Sam]
  BUSINESS_WORDS = %w[Pty Ltd Inc Co Aus Hire Bank Host Plus Sole Tax Aid Job Sub Fund]
  OTHER_WORDS = %w[The Van Of And For As Is Home No East West Mind Menu Sub Fund]

  def self.capitalize(name)
    exceptions = PEOPLE_NAMES + BUSINESS_WORDS + OTHER_WORDS

    CapitalizeNames.capitalize(name)
                   .gsub(/(\()([a-z])/) { "#{::Regexp.last_match(1)}#{::Regexp.last_match(2).upcase}" }
                   .gsub(/(\d)([a-z])/) { "#{::Regexp.last_match(1)}#{::Regexp.last_match(2).upcase}" }
                   .gsub(/\b\w{2,4}\b/) do |acronym|
                     exceptions.include?(acronym) ? acronym : acronym.upcase
                   end
  end
end