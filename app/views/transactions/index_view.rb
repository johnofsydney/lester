class Transactions::IndexView < ApplicationView
  include ActionView::Helpers::NumberHelper

	def initialize(transactions:)
		@transactions = transactions
	end

	def template
		h1 { 'transactions' }

    table(class: 'table') do
      tr do
        th { 'Amount' }
        th { 'Donor' }
        th { 'Donee' }
        th { 'Date' }
      end

      @transactions.each do |transaction|
        tr do
          td { a(href: "/transactions/#{transaction.id}") { number_to_currency(transaction.amount) } }
          td { a(href: "/people/#{transaction.giver_id}") { transaction.giver.name } if transaction.giver }
          td { a(href: "/people/#{transaction.taker_id}") { transaction.taker.name } if transaction.taker }
          td { transaction.date.strftime("%m/%d/%Y") }
        end
      end
    end
	end
end