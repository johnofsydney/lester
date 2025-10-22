class People::ShowView < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :person

  def initialize(person:)
    # TODO: push the .cached version further up the stack. stop passing around group
    @person = person
  end

  def view_template
    render Common::Heading.new(entity: person)

    render Common::StatsSummary.new(
      klass: 'Person',
      direct_connections: person.cached.direct_connections,
      money_in: person.cached.money_in,
      money_out: person.cached.money_out
    )
    render Common::GraphSummary.new(entity: person)

    render People::GroupsTable.new(person:)

    render TransfersTableComponent.new(
      entity: person,
      transfers: person.cached.consolidated_transfers,
      heading: "Directly connected to #{person.name}"
      # summarise_for: Group.summarise_for
    )
  end
end
