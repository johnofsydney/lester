require 'capitalize_names'

class Nodes::NameCapitalizer
  PEOPLE_NAMES = %w[Ann Anna Anne Bob Brad Diaz Dyer Gai Greg Holt Hugh Ian Jan Jane Jess John Kain Kate Kaur Lee Lucy Luke Marc Mark Paul Pete Ross Ryan Sam Sep Tony Troy Zali Zoe].freeze
  BUSINESS_WORDS = %w[Aid Aus Bank Co Corp Data Fund Hays Hire Host Inc Job Ltd Plus Pty Rio Root Sole Sub Tax Toll Web].freeze
  OTHER_WORDS = %w[Able Air And Anti Are Arts As Asia Bay Bell Blue Body Car City Diet Dim East Fair Foot For Fund Gin Gold Hall Hat Hide Hive Home Hook Hull Is Land Let Man Menu Mind No Now Of Oh Park Ping Red Reef San Seek Snow Sub Talk The To Van Wall West Work].freeze

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