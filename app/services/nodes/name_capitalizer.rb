require 'capitalize_names'

class Nodes::NameCapitalizer
  PEOPLE_NAMES = %w[Greg Paul John Pete Jan Troy Lucy Marc Sep Mark Kate Sam Hugh Ann Ross Ian Kain Anna Zoe Luke Holt Zali Ryan Gai Lee Jane Dyer Tony].freeze
  BUSINESS_WORDS = %w[Pty Ltd Inc Co Aus Hire Bank Host Plus Sole Tax Aid Job Sub Fund Toll Root Web Data Corp Hays Rio].freeze
  OTHER_WORDS = %w[The To Of And For As Is Home No East West Mind Menu Sub Fund Let Talk Red Man Hat Asia Hive Ping Arts Van Body Gold Wall Air Hide Seek Dim Gin San Reef Oh Snow Hook].freeze

  def self.capitalize(name)
    raise "Nodes::NameCapitalizer.capitalize backtrace:\n#{caller.join("\n")}" if name.blank?

    return unless name.is_a?(String)

    exceptions = PEOPLE_NAMES + BUSINESS_WORDS + OTHER_WORDS

    CapitalizeNames.capitalize(name)
                   .gsub(/(\()([a-z])/) { "#{::Regexp.last_match(1)}#{::Regexp.last_match(2).upcase}" } # capitalise first letter after an open bracket
                   .gsub(/(\d)([a-z])/) { "#{::Regexp.last_match(1)}#{::Regexp.last_match(2).upcase}" } # capitalise first letter after a number
                   .gsub(/\b\w{2,4}\b/) { |acronym| exceptions.include?(acronym) ? acronym : acronym.upcase } # upcase any 2-4 letter words, unless they are in the exceptions list
  end
end