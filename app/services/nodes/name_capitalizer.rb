require 'capitalize_names'

class Nodes::NameCapitalizer
  PEOPLE_NAMES = %w[Greg Paul John Pete Jan Troy Lucy Marc Sep Mark Kate Sam Hugh Ann Ross Ian Kain Anna].freeze
  BUSINESS_WORDS = %w[Pty Ltd Inc Co Aus Hire Bank Host Plus Sole Tax Aid Job Sub Fund Toll Root Web Data Corp Hays].freeze
  OTHER_WORDS = %w[The To Of And For As Is Home No East West Mind Menu Sub Fund Let Talk Red Man Hat Asia Hive Ping Arts Van Body Gold Wall Air Hide Seek Dim Gin San].freeze

  def self.capitalize(name)
    return unless name.present? # should be a raise really
    return unless name.is_a?(String)

    exceptions = PEOPLE_NAMES + BUSINESS_WORDS + OTHER_WORDS

    CapitalizeNames.capitalize(name)
                   .gsub(/(\()([a-z])/) { "#{::Regexp.last_match(1)}#{::Regexp.last_match(2).upcase}" } # capitalise first letter after an open bracket
                   .gsub(/(\d)([a-z])/) { "#{::Regexp.last_match(1)}#{::Regexp.last_match(2).upcase}" } # capitalise first letter after a number
                   .gsub(/\b\w{2,4}\b/) do |acronym|
                     exceptions.include?(acronym) ? acronym : acronym.upcase
                   end
  end
end