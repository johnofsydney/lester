class Groups::Person < ApplicationView
	def initialize(person:, exclude_group: nil)
		@person = person
    @exclude_group = exclude_group
    @membership = Membership.find_by(group: exclude_group, member: person)
	end

  attr_reader :person, :exclude_group, :membership

  def template
    tr do
      td do
        span { a(href: "/people/#{person.id}") { person.name } }
        if membership.evidence.present?
          span { '   ' }
          span { a(href: membership.evidence, class: 'gentle-link', target: '_blank') { '...' } }
        end
      end
      td do
        span {last_position_and_title}
        if last_position&.evidence.present?
          span { '   ' }
          span { a(href: last_position.evidence, class: 'gentle-link', target: '_blank') { '...' } }
        end
      end
      td do
        if person.memberships.length == 1 # it me
          ''
        elsif person.memberships.length < 8
          memberships = person.memberships - Membership.where(member: person, group: exclude_group)

          if memberships.length < 300
            ul(class: 'list-group') do
              memberships.each do |membership|
                li(class: 'list-group-item') do
                  a(href: "/groups/#{membership.group.id}") { membership.group.name }
                  # TODO FIX THIS FOR GROUPS AS MEMBERS
                end
              end
            end
          end
        else
          "#{group.memberships.length} members"
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
      result += " | (#{position.formatted_start_date} - #{position.formatted_end_date})"
    elsif position.start_date.present?
      result += " | (since #{position.start_date})"
    elsif position.end_date.present?
      result += " | (until #{position.end_date})"
    end

    result
  end
end
