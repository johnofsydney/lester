class People::Group < ApplicationView
	def initialize(group:, exclude_person: nil)
		@group = group
    @exclude_person = exclude_person
    @membership = Membership.find_by(group: group, person: exclude_person)
	end

  attr_reader :group, :exclude_person, :membership

	def template
    header_style = element_styles(group)




    link_text = "#{group.name}#{memership_timeframe}#{last_position}".html_safe

    div(class: 'group card border-primary mb-3', style: 'max-width: 18rem;') do

      link_for(
        entity: group,
        class: 'btn btn-sm btn-outline-primary',
        style: button_styles(group),
        link_text:
      )

      if (group.memberships - Membership.where(person: exclude_person, group: group)).present?
        div(class: 'card-body text-primary') do
          group.memberships.each do |membership|
            next if exclude_person && membership.person == exclude_person
            person = membership.person


            link_for(
              entity: person,
              class: 'btn btn-sm btn-outline-primary btn-smaller',
              style: button_styles(person, 1),
              link_text: person.name
            )
          end
        end
      end
    end
  end

  def memership_timeframe
    return unless membership.start_date || membership.end_date
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
