# require_relative '../components/transfers_table_component'

class Groups::ShowView < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :group

	def initialize(group:)
		@group = group
	end

	def template
    div(class: 'heading') do
      href = "https://www.google.com/search?q=#{group.name}"
      a(
        href:,
        class: 'btn w-100',
        style: button_styles(group),
        target: :_blank
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
      heading: "Connected to #{group.name} to a depth of #{depth} degrees of separation",
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