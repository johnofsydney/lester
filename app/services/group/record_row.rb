# Creates or Finds a Membership Record for a Group and Person (and a Position if title given)
# args
# group:, Group record
# person:, Person record -- caller resolves/cleans the Person first (e.g. via People::RecordPerson)
# title: String title -- optional, - Used for Position title
# evidence: String evidence -- optional, - Used for Membership evidence
# start_date: String or Date - used for Membership, and mirrored onto the Position if title given
# end_date: String or Date - used for Membership, and mirrored onto the Position if title given

require 'capitalize_names'
class Group::RecordRow
  def initialize(group:, person:, title: nil, evidence: nil, start_date: nil, end_date: nil)
    @group = group
    @person = person
    @title = nice_title(title)
    @evidence = evidence
    @start_date = start_date
    @end_date = end_date
  end

  def call
    membership = find_or_create_open_membership
    apply_membership_attributes(membership)
    apply_position(membership) if title.present?
    membership
  end

  private

  attr_reader :group, :person, :title, :evidence, :start_date, :end_date

  # Scoped to end_date: nil so a person returning after a prior stint doesn't reopen
  # their old (closed) Membership row -- each stint gets its own row (see Membership's
  # documented Wayne Rooney/Everton/Man Utd example).
  def find_or_create_open_membership
    Membership.where(group:, member: person, end_date: nil).first_or_create!
  end

  def apply_membership_attributes(membership)
    membership.start_date = start_date if start_date.present? && membership.start_date.blank?
    membership.end_date = end_date if end_date.present?
    membership.evidence = evidence if evidence.present? && membership.evidence.blank?
    membership.save! if membership.changed?
  end

  # A Position's dates always mirror its Membership's -- kept in sync here rather than only set
  # once at creation, so a Position for a councillor closed out later (see
  # Councils::{Nsw,Vic}::ImportCouncilResultRowJob#close_departed_members, which updates
  # Membership#end_date directly) doesn't go stale relative to it.
  def apply_position(membership)
    position = Position.find_or_create_by(membership:, title:)
    position.start_date = membership.start_date
    position.end_date = membership.end_date
    position.save! if position.changed?
  end

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
