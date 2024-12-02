class People::ShowView < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :person

	def initialize(person:)
		@person = person
	end

	def template
    render Common::Heading.new(entity: person)
    a(href: "/people/#{person.id}/network_graph") { 'Network Graph' }


    render Common::MoneySummary.new(entity: person)
    render People::Groups.new(groups: person.groups, person: person)

    depth = 6

    render TransfersTableComponent.new(
      entity: person,
      transfers: person.consolidated_transfers(depth: 0),
      heading: "Transfers connected to #{person.name} to a depth of #{depth} degrees of separation",
      summarise_for: Group.summarise_for
    )

    turbo_frame(id: 'feed', src: lazy_load_person_path, loading: :lazy) do
      p(class: 'grey') { 'Fetching More Transfer Records...'  }
      hr
    end
	end
end
