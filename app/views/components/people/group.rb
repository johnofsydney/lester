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
        if membership.evidence.present?
          span { '   ' }
          span { a(href: membership.evidence, target: '_blank') { '...' } }
        end
      end
      td do
        span {last_position_and_title}

        if last_position&.evidence.present?
          span { '   ' }
          span { a(href: last_position.evidence, target: '_blank') { '...' } }
        end
      end
      td do
        if group.memberships.count == 1
          ''
        elsif group.memberships.count < 8
          memberships = group.memberships - Membership.where(member: exclude_person, group: group)

          ul(class: 'list-group list-group-horizontal') do
          memberships.each do |membership|
              li(class: 'list-group-item') do
                a(href: "/#{membership.member_type.downcase.pluralize}/#{membership.member.id}") { membership.member.name }
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
  def last_position
    membership&.last_position
  end

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
