# require_relative '../components/transfers_table_component'

class Groups::ShowView < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :group

	def initialize(group:)
		@group = group
	end

	def template
    a(href: "/groups/#{group.id}", class: 'btn w-100', style: button_styles(group)) { group.name }
    render PrimaryNodesMenuComponent.new(entity: group)

    depth = 6
    render TransfersTableComponent.new(
      entity: group,
      transfers: group.consolidated_transfers(depth:),
      heading: "Transfers connected to #{group.name} to a depth of #{depth} degrees of separation",
      summarise_for: ['Australian Labor Party', 'The Coalition']
    )

    render FooterComponent.new(entity: group)
	end
end