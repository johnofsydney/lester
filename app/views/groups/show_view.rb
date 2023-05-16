class Groups::ShowView < ApplicationView
  include ActionView::Helpers::NumberHelper

  attr_reader :group, :incoming_transactions, :outgoing_transactions

	def initialize(group:)
		@group = group
    # @incoming_transactions = group.transactions.select{|transaction| transaction.taker_id == group.id}
    # @outgoing_transactions = group.transactions.select{|transaction| transaction.giver_id == group.id}
    @incoming_transactions = Transaction.where(taker_id: group.id)
    @outgoing_transactions = Transaction.where(giver_id: group.id)
	end

	def template
    # div(class: 'col-md-4') do
      # div(class: 'card') do
        # div(class: 'card-body') do
          a(href: "/groups/#{group.id}", class: 'btn w-100', style: button_styles(group)) { group.name }

          h3 { 'Transactions In' }
          table(class: 'table') do
            tr do
              th { 'Amount' }
              th { 'Giver' }
              th { 'Date' }
            end

            incoming_transactions.each do |transaction|
              tr do
                td { number_to_currency(transaction.amount.to_s) }
                td { a(href: "/#{class_of_giver(transaction.giver)}/#{transaction.giver_id}") { transaction.giver.name } }
                td { transaction.date.strftime("%d/%m/%Y") }
              end
            end
          end


          h3 { 'Transactions Out' }
          table(class: 'table') do
            tr do
              th { 'Amount' }
              th { 'Taker' }
              th { 'Date' }
            end


            outgoing_transactions.each do |transaction|
              tr do
                td { number_to_currency(transaction.amount.to_s) }
                td { transaction.taker.name.to_s }
                td { transaction.date.strftime("%d/%m/%Y") }
              end
            end
          end


        # end

        group.people.each do |person|
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
      # end
    # end

    a(href: '/groups/new', class: 'btn btn-primary') { 'New Group' }
    a(href: "/groups/#{group.id}/edit", class: 'btn btn-primary') { 'Edit Group' }
    a(href: '/people/', class: 'btn btn-primary') { 'People' }
	end

  def class_of_giver(giver)
    giver.is_a?(Group) ? 'groups' : 'people'
  end
end