class Transactions::ShowView < ApplicationView

  attr_reader :transaction

	def initialize(transaction:)
		@transaction = transaction
	end

	def template
    div(class: 'col-md-4') do
      div(class: 'card') do
        div(class: 'card-body') do
          a(href: "/transactions/#{transaction.id}", class: 'btn w-100', style: button_styles(transaction)) { transaction.amount.to_s }
          a(href: "/transactions/#{transaction.giver_id}", class: 'btn w-100', style: button_styles(transaction)) { transaction.giver.name.to_s }
          a(href: "/transactions/#{transaction.taker_id}", class: 'btn w-100', style: button_styles(transaction)) { transaction.taker.name.to_s }
        end
      end
    end

    # main menu
    span { strong { 'see also footer' } }
    a(href: '/groups/', class: 'btn btn-primary') { 'Groups' }
    a(href: '/transactions/', class: 'btn btn-primary') { 'Transactions' }
    a(href: '/people/', class: 'btn btn-primary') { 'People' }
    a(href: '/imports/annual_donor/', class: 'btn btn-primary') { 'TEMP | IMPORT DONATIONS' }
	end
end