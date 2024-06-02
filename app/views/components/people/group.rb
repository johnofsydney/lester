class People::Group < ApplicationView
	def initialize(group:, exclude_person: nil)
		@group = group
    @exclude_person = exclude_person
    @membership = Membership.find_by(group: group, member: exclude_person)
	end

  attr_reader :group, :exclude_person, :membership

  def template
    tr do
      td do
        a(href: "/groups/#{group.id}") { group.name }
      end
      td { last_position_and_title  }
      td do
        if group.memberships.count == 1
          ''
        elsif group.memberships.count < 8
          memberships = group.memberships - Membership.where(member: exclude_person, group: group)

          ul(class: 'list-group list-group-horizontal') do
          memberships.each do |membership|
              li(class: 'list-group-item') do
                a(href: "/people/#{membership.member.id}") { membership.member.name }
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

  def last_position_and_title
    position = membership&.last_position

    return '' unless position

    result = position.title
    return '' unless result

    if position.end_date.present? && position.start_date.present?
      result += " (#{position.start_date.strftime("%d/%m/%y")} - #{position.end_date.strftime("%d/%m/%y")})"
    elsif position.start_date.present?
      result += " (since #{position.start_date.strftime("%d/%m/%y")})"
    elsif position.end_date.present?
      result += " (until #{position.end_date.strftime("%d/%m/%y")})"
    end

    result
  end
end
