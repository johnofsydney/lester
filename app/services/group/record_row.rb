# Creates or Finds a Membership Record for a Group and Person (and a Position if title given)
# args
# group:, Group record
# person_name:, String person name
# title: String title -- optional, - Used for Position title
# evidence: String evidence -- optional, - Used for Membership AND Position evidence
# start_date: String or Date - used for Membership BUT NOT Position start_date,
# end_date: String or Date - used for Membership BUT NOT Position end_date

require 'capitalize_names'
class Group::RecordRow
  def initialize(group:, person_name:, title: nil, evidence: nil, start_date: nil, end_date: nil)
    @group = group
    @person_name = person_name
    @title = nice_title(title)
    @evidence = evidence
    @start_date = start_date
    @end_date = end_date
  end

  def call
    person = RecordPerson.call(person_name)
    membership = Membership.find_or_create_by(group:, member: person)
    Position.find_or_create_by(membership:, title:) if title.present?
  end

  private

  attr_reader :group, :person_name, :title, :evidence, :start_date, :end_date

  def nice_title(title)
    return if title.blank?

    regex_for_two_and_three_chars = /(\b\w{2,3}\b)|(\b\w{2,3}\d)/
    regex_for_downcase = /\bthe\b|\bof\b|\band\b|\bas\b|\bfor\b|\bis\b/i

    CapitalizeNames.capitalize(title.strip)
                   .gsub(regex_for_two_and_three_chars, &:upcase)
                   .gsub(regex_for_downcase, &:downcase)
                   .gsub(/^the/, &:titleize)
  end
end
