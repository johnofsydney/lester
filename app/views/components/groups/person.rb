class Groups::Person < ApplicationView
	def initialize(person:, exclude_group: nil)
		@person = person
    @exclude_group = exclude_group
	end

  attr_reader :person, :exclude_group

  def template
    tr do
      td do
        a(href: "/people/#{person.id}") { person.name }
      end
      td do
        position
      end
      td do
        if person.memberships.count == 1 # it me
          ''
        elsif person.memberships.count < 8
          memberships = person.memberships - Membership.where(member: person, group: exclude_group)

          # ul(class: 'list-group list-group-horizontal') do
          ul(class: 'list-group') do
            memberships.each do |membership|
              # li(class: 'list-group-item horizontal-button') do
              li(class: 'list-group-item') do
                a(href: "/groups/#{membership.group.id}") { membership.group.name }
                # TODO FIX THIS FOR GROUPS AS MEMBERS
              end
            end
          end
        else
          "#{group.memberships.count} members"
        end
      end
    end
  end

  private

  def position
    position = Membership.find_by(group: exclude_group, member: person)&.positions&.last

    return '' unless position

    result = position.title
    return '' unless result

    if position.end_date.present? && position.start_date.present?
      result += " | (#{position.formatted_start_date} - #{position.formatted_end_date})"
    elsif position.start_date.present?
      result += " | (since #{position.start_date})"
    elsif position.end_date.present?
      result += " | (until #{position.end_date})"
    end

    result
  end
end
