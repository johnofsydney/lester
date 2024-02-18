class Groups::Person < ApplicationView
	def initialize(person:, exclude_group: nil)
		@person = person
    @exclude_group = exclude_group
	end

  attr_reader :person, :exclude_group

	def template
    header_style = element_styles(person)
    membership = Membership.find_by(group: exclude_group, person:)

    div(class: 'person card border-primary mb-3', style: 'max-width: 18rem;') do
      link_for(
        entity: person,
        class: 'btn btn-sm btn-outline-primary',
        style: button_styles(person),
        link_text: person.name
      )

      if (person.memberships - Membership.where(person:, group: exclude_group)).present?
        div(class: 'card-body text-primary') do
          person.memberships.each do |membership|
            next if exclude_group && membership.group == exclude_group
            group = membership.group

            link_for(
              entity: group,
              class: 'btn btn-sm btn-outline-primary btn-smaller',
              style: button_styles(group, 1),
              link_text: group.name
            )
          end
        end
      end
    end
  end
end
