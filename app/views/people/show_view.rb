class People::ShowView < ApplicationView
  include ActionView::Helpers::NumberHelper
  include Phlex::Rails::Helpers::ContentFor

  attr_reader :person

  def initialize(person:)
    # TODO: push the .cached version further up the stack. stop passing around person
    @person = person
  end

  def view_template
    render Common::Heading.new(entity: person.cached)

    render Common::StatsSummary.new(
      klass: 'Person',
      direct_connections: person.cached.direct_connections,
      money_in: person.cached.money_in,
      money_out: person.cached.money_out
    )
    render Common::GraphSummary.new(entity: person.cached)

    render People::GroupsTable.new(person:)

    render TransfersTableComponent.new(
      entity: person,
      transfers: person.cached.consolidated_transfers,
      heading: "Directly connected to #{person.name}"
      # summarise_for: Group.summarise_for
    )


    if Current.admin_user?
      content_for :admin_sidebar do
        div(
          class: 'admin-links d-none d-lg-flex flex-column align-items-start bg-light ps-4 pe-4 mt-4',
          style: 'min-width: 250px; min-height: 100vh;'
        ) do
          a(href: "/admin/people/#{person.id}", class: 'btn btn-sm btn-outline-primary mb-2 w-100') { 'Edit Person in Admin' }
        end
      end
    end
  end
end
