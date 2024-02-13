class People::ShowView < ApplicationView

  attr_reader :person

	def initialize(person:)
		@person = person
	end

	def template
    render MenuComponent.new(entity: person)

    div(class: 'heading') do
      a(
        href: "/people/#{person.id}",
        class: 'btn w-100',
        style: button_styles(person)
      ) { person.name }
    end

    div(class: 'direct-descendents') do
      render PrimaryNodesMenuComponent.new(entity: person)
    end

    depth = 6
    render TransfersTableComponent.new(
      entity: person,
      transfers: person.consolidated_transfers(depth:),
      heading: "Transfers connected to #{person.name} to a depth of #{depth} degrees of separation",
      summarise_for: summarise_for
    )
	end

    def summarise_for
    major_groupings = %i(coalition nationals labor green liberals)
    states = %i[federal nsw vic qld sa wa nt act tas]

    major_groupings.map do |group|
      states.map do |state|
        Group::NAMES.send(group).send(state) if Group::NAMES.send(group)
      end
    end.flatten.compact
  end
end
