class Groups::ShowView < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :group

	def initialize(group:)
		@group = group
	end

	def template
    a(href: "/groups/#{group.id}", class: 'btn w-100', style: button_styles(group)) { group.name }


    h2 { 'First Degree' }
    h3 { "Transfers In (#{group.first_degree_received_transfers.count} records)" }
    table(class: 'table') do
      tr do
        th { 'Amount' }
        th { 'Year' }
        th { 'Giver' }
        th { 'Taker' }
      end

      group.first_degree_received_transfers.each do |summary|
        tr do
          td { number_to_currency(summary.amount.to_s, precision: 0) }
          td { summary.effective_date.year.to_s }
          td { a(href: "/#{class_of(summary.giver)}/#{summary.giver.id}") { summary.giver.name } }
          td { a(href: "/#{class_of(summary.taker)}/#{summary.taker.id}") { summary.taker.name } }
        end
      end
    end

    h3 { "Transfers Out (#{group.first_degree_given_transfers.count} records)" }
    table(class: 'table') do
      tr do
        th { 'Amount' }
        th { 'Year' }
        th { 'Giver' }
        th { 'Taker' }
      end

      group.first_degree_given_transfers.each do |summary|
        tr do
          td { number_to_currency(summary.amount.to_s, precision: 0) }
          td { summary.effective_date.year.to_s }
          td { a(href: "/#{class_of(summary.giver)}/#{summary.giver.id}") { summary.giver.name } }
          td { a(href: "/#{class_of(summary.taker)}/#{summary.taker.id}") { summary.taker.name } }
        end
      end
    end

    h2 { 'Second Degree' }
    h3 { "Transfers In (#{group.second_degree_received_transfers.count} records)" }
    table(class: 'table') do
      tr do
        th { 'Amount' }
        th { 'Year' }
        th { 'Giver' }
        th { 'Taker' }
      end

      group.second_degree_received_transfers.each do |summary|
        tr do
          td { number_to_currency(summary.amount.to_s, precision: 0) }
          td { summary.effective_date.year.to_s }
          td { a(href: "/#{class_of(summary.giver)}/#{summary.giver.id}") { summary.giver.name } }
          td { a(href: "/#{class_of(summary.taker)}/#{summary.taker.id}") { summary.taker.name } }
        end
      end
    end

    h3 { "Transfers Out (#{group.second_degree_given_transfers.count} records)" }
    table(class: 'table') do
      tr do
        th { 'Amount' }
        th { 'Year' }
        th { 'Giver' }
        th { 'Taker' }
      end

      group.second_degree_given_transfers.each do |summary|
        tr do
          td { number_to_currency(summary.amount.to_s, precision: 0) }
          td { summary.effective_date.year.to_s }
          td { a(href: "/#{class_of(summary.giver)}/#{summary.giver.id}") { summary.giver.name } }
          td { a(href: "/#{class_of(summary.taker)}/#{summary.taker.id}") { summary.taker.name } }
        end
      end
    end

    h2 { 'Third Degree' }
    h3 { "Transfers In (#{group.third_degree_received_transfers.count} records)" }
    table(class: 'table') do
      tr do
        th { 'Amount' }
        th { 'Year' }
        th { 'Giver' }
        th { 'Taker' }
      end

      group.third_degree_received_transfers.each do |summary|
        tr do
          td { number_to_currency(summary.amount.to_s, precision: 0) }
          td { summary.effective_date.year.to_s }
          td { a(href: "/#{class_of(summary.giver)}/#{summary.giver.id}") { summary.giver.name } }
          td { a(href: "/#{class_of(summary.taker)}/#{summary.taker.id}") { summary.taker.name } }
        end
      end
    end

    h3 { "Transfers Out (#{group.third_degree_given_transfers.count} records)" }
    table(class: 'table') do
      tr do
        th { 'Amount' }
        th { 'Year' }
        th { 'Giver' }
        th { 'Taker' }
      end

      group.third_degree_given_transfers.each do |summary|
        tr do
          td { number_to_currency(summary.amount.to_s, precision: 0) }
          td { summary.effective_date.year.to_s }
          td { a(href: "/#{class_of(summary.giver)}/#{summary.giver.id}") { summary.giver.name } }
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

    hr





    a(href: '/groups/new', class: 'btn btn-primary') { 'New Group' }
    a(href: "/groups/#{group.id}/edit", class: 'btn btn-primary') { 'Edit Group' }
    a(href: '/people/', class: 'btn btn-primary') { 'People' }
	end

  def class_of(klass)
    klass.is_a?(Group) ? 'groups' : 'people'
  end
end