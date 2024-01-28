# require_relative '../components/transfers_table_component'

class Groups::ShowView < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :group

	def initialize(group:)
		@group = group
	end

	def template
    render MenuComponent.new(entity: group)

    div(class: 'heading') do
      a(
        href: "/groups/#{group.id}",
        class: 'btn w-100',
        style: button_styles(group)
      ) { group.name }
    end

    div(class: 'direct-descendents') do
      render PrimaryNodesMenuComponent.new(entity: group)
    end


    depth = 6
    render TransfersTableComponent.new(
      entity: group,
      transfers: group.consolidated_transfers(depth:),
      heading: "Transfers connected to #{group.name} to a depth of #{depth} degrees of separation",
      summarise_for: ['Australian Labor Party', 'The Coalition']
    )
	end
end