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

    if group.affiliated_groups.present?
      hr
      render Groups::AffiliatedGroups.new(groups: group.affiliated_groups)
    end

    if group.people.present?
      hr
      render Groups::People.new(people: group.people, group: group)
    end





    depth = 6
    render TransfersTableComponent.new(
      entity: group,
      transfers: group.consolidated_transfers(depth:),
      heading: "Transfers connected to #{group.name} to a depth of #{depth} degrees of separation",
      summarise_for: summarise_for
    )
	end

  def summarise_for
    major_groupings = %i(coalition nationals labor green liberals)
    states = %i[federal nsw vic qld sa wa nt act tas]

    list = major_groupings.map do |group|
      states.map do |state|
        Group::NAMES.send(group).send(state) if Group::NAMES.send(group)
      end
    end

    list.flatten.compact.uniq - [group.name]
  end
end