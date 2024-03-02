class People::Group < ApplicationView
	def initialize(group:, exclude_person: nil)
		@group = group
    @exclude_person = exclude_person
    @membership = Membership.find_by(group: group, person: exclude_person)
	end

  attr_reader :group, :exclude_person, :membership

  def template
    tr do
      td { group.name }
      td { Membership.find_by(group: group, person: exclude_person)&.positions&.last&.title  }
      td do
        if group.memberships.count < 8
          memberships = group.memberships - Membership.where(person: exclude_person, group: group)

          "#{memberships.map{|m| m.person.name  }}"
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
end
