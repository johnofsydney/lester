class People::ShowView < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :person

	def initialize(person:)
		@person = person
	end

	def template
    render Common::Heading.new(entity: person)
    render Common::StatsSummary.new(entity: person)
    render Common::GraphSummary.new(entity: person)
    render People::GroupsTable.new(groups: person.groups, person: person)

    render TransfersTableComponent.new(
      entity: person,
      transfers: person.consolidated_transfers(depth: 0),
      heading: "Directly connected to #{person.name}",
      summarise_for: Group.summarise_for
    )

    turbo_frame(id: 'feed', src: lazy_load_person_path, loading: :lazy) do
      p(class: 'grey') { 'Fetching More Transfer Records...'  }
    end
	end
end
