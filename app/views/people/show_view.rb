class People::ShowView < ApplicationView

  attr_reader :person

	def initialize(person:)
		@person = person
	end

	def template
    a(href: "/people/#{person.id}", class: 'btn w-100', style: button_styles(person)) { person.name }
    render PrimaryNodesMenuComponent.new(entity: person)

    depth = 6
    render TransfersTableComponent.new(
      entity: person,
      transfers: person.consolidated_transfers(depth:),
      heading: "Transfers connected to #{person.name} to a depth of #{depth} degrees of separation",
      summarise_for: ['Australian Labor Party', 'The Coalition']
    )



    render FooterComponent.new(entity: person)
	end
end
