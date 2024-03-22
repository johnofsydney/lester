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
      td { position  }
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

  def memership_timeframe
    return unless membership.start_date && membership.end_date
    "<br>#{membership.start_date.year} - #{membership.end_date.year}"
  end

  def last_position
    return if membership.positions.empty?

    position = membership.positions.last # TODO: sort by date
    title = position.title if position&.title
    timeframe = position.start_date.strftime("%d/%m/%y") if position&.start_date
    timeframe = "#{timeframe} - #{position.end_date.strftime("%d/%m/%y")}" if position&.end_date

    "<br>#{title}: #{timeframe}"
  end

private

  def position
    position = Membership.find_by(group: group, member: exclude_person)&.positions&.last

    return '' unless position

    result = position.title
    return '' unless result

    if position.end_date.present? && position.start_date.present?
      result += " (#{position.start_date} - #{position.end_date})"
    elsif position.start_date.present?
      result += " (since #{position.start_date})"
    elsif position.end_date.present?
      result += " (until #{position.end_date})"
    end

    result
  end
end
