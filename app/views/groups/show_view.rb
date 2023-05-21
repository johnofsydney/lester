class Groups::ShowView < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :group

	def initialize(group:)
		@group = group
	end

	def template
    a(href: "/groups/#{group.id}", class: 'btn w-100', style: button_styles(group)) { group.name }

    table(class: 'table') do
      tr do
        th { 'Money In' }
        th { 'Money Out' }
        th { group.net_sum > 0 ? 'Net (In)' : 'Net (Out)' }
      end

      tr do
        td { number_to_currency(group.incoming_sum, precision: 0) }
        td { number_to_currency(group.outgoing_sum, precision: 0) }
        td { number_to_currency(group.net_sum.abs, precision: 0) }
      end
    end

    h3 { "Transfers In (#{group.incoming_transfers.count} records)" }
    table(class: 'table') do
      tr do
        th { 'Amount' }
        th { 'Year' }
        th { 'Giver' }
      end

      group.incoming_transfers.each do |summary|
        tr do
          td { number_to_currency(summary.amount.to_s, precision: 0) }
          td { summary.effective_date.year.to_s }
          td { a(href: "/#{class_of(summary.giver)}/#{summary.giver.id}") { summary.giver.name } }
        end
      end
    end

    h3 { "Transfers Out (#{group.outgoing_transfers.count} records)" }
    table(class: 'table') do
      tr do
        th { 'Amount' }
        th { 'Year' }
        th { 'Giver' }
      end

      group.outgoing_transfers.each do |summary|
        tr do
          td { number_to_currency(summary.amount.to_s, precision: 0) }
          td { summary.effective_date.year.to_s }
          td { a(href: "/#{class_of(summary.taker)}/#{summary.taker.id}") { summary.taker.name } }
        end
      end
    end


    hr

    group.people.each do |person|
      # TODO: add title from membership here...
      div(class: 'list-group-item flex-normal') do
        div do
          a(href: "/people/#{person.id}", class: 'btn-primary btn', style: button_styles(person)) { person.name }
        end
        div do
          person.groups.each do |group|
            a(href: "/groups/#{group.id}", class: 'btn-secondary btn btn-sml', style: button_styles(group) ) { group.name }
          end
        end
      end
    end

    h3 { "Transfers Out (by Members) (#{group.people_transfers.outgoing_transfers.count} records)" }
    table(class: 'table') do
      tr do
        th { 'Amount' }
        th { 'Year' }
        th { 'Giver' }
        th { 'Taker' }
      end

      group.people_transfers.outgoing_transfers.each do |summary|
        tr do
          td { number_to_currency(summary.amount.to_s, precision: 0) }
          td { summary.effective_date.year.to_s }
          td { a(href: "/#{class_of(summary.giver)}/#{summary.giver.id}") { summary.giver.name } }
          td { a(href: "/#{class_of(summary.taker)}/#{summary.taker.id}") { summary.taker.name } }
        end
      end
    end

    h3 { "Transfers Out (third degree) (#{group.third_degree_transfers.outgoing_transfers.count} records)" }
    table(class: 'table') do
      tr do
        th { 'Amount' }
        th { 'Year' }
        th { 'Giver' }
        th { 'Taker' }
      end

      group.third_degree_transfers.outgoing_transfers.each do |summary|
        tr do
          td { number_to_currency(summary.amount.to_s, precision: 0) }
          td { summary.effective_date.year.to_s }
          td { a(href: "/#{class_of(summary.giver)}/#{summary.giver.id}") { summary.giver.name } }
          td { a(href: "/#{class_of(summary.taker)}/#{summary.taker.id}") { summary.taker.name } }
        end
      end
    end



    a(href: '/groups/new', class: 'btn btn-primary') { 'New Group' }
    a(href: "/groups/#{group.id}/edit", class: 'btn btn-primary') { 'Edit Group' }
    a(href: '/people/', class: 'btn btn-primary') { 'People' }
	end

  def class_of(klass)
    klass.is_a?(Group) ? 'groups' : 'people'
  end
end