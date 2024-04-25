class People::ShowView < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :person

	def initialize(person:)
		@person = person
	end

	def template
    div(class: 'heading') do
      href = "https://www.google.com/search?q=#{person.name}"
      a(
        href:,
        class: 'btn w-100',
        style: button_styles(person),
        target: :_blank
      ) { person.name }
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


    if person.groups.present?
      hr
      render People::Groups.new(groups: person.groups, person: person)
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

    def money_in
    amount = Transfer.where(taker: person).sum(:amount)
    return unless amount.positive?

    number_to_currency amount, precision: 0
  end

  def money_out
    amount = Transfer.where(giver: person).sum(:amount)
    return unless amount.positive?
    # binding.pry
    number_to_currency amount, precision: 0
  end
end
