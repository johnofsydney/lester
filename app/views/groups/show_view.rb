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

    if money_in.present? || money_out.present?
      hr
      div(class: 'row') do
        h2 { 'Money Summary' }
        div(class: 'col') do
          h3 { 'Money In' }
          p { money_in }
        end
        div(class: 'col') do
          h3 { 'Money Out' }
          p { money_out }
        end
      end
    end

    if group.affiliated_groups.present?
      hr
      div(class: 'row') do
        h2 { 'Affiliated Groups' }
        # render Groups::AffiliatedGroups.new(groups: group.affiliated_groups)
        ul(class: 'list-group list-group-horizontal') do
          group.affiliated_groups.each do |group|
            li(class: 'list-group-item') do
              a(href: "/groups/#{group.id}") { group.name }
            end
          end

        end
      end
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

  def money_in
    amount = Transfer.where(taker: group).sum(:amount)
    return unless amount.positive?

    number_to_currency amount, precision: 0
  end

  def money_out
    amount = Transfer.where(giver: group).sum(:amount)
    return unless amount.positive?

    number_to_currency amount, precision: 0
  end
end