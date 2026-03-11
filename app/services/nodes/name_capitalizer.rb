require 'capitalize_names'

class Nodes::NameCapitalizer
  def self.capitalize(name)
    exceptions = %w[The Pty Ltd Inc Co Van Aus Of And For As Is Hire Bank Home Host Plus Greg Paul Sole John Pete Jan Troy Lucy Sole Tax Aid Job Marc Sep Mark Kate Sam No East West Care Mind Menu Sub Fund]

    CapitalizeNames.capitalize(name)
                   .gsub(/(\()([a-z])/) { "#{$1}#{$2.upcase}" }
                   .gsub(/(\d)([a-z])/) { "#{$1}#{$2.upcase}" }
                   .gsub(/\b\w{2,4}\b/) do |acronym|
                     exceptions.include?(acronym) ? acronym : acronym.upcase
                   end
  end
end