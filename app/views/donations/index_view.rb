class Donations::IndexView < ApplicationView
  include ActionView::Helpers::NumberHelper

	def initialize(donations:)
		@donations = donations
	end

	def template
		h1 { 'donations' }

    table(class: 'table') do
      tr do
        th { 'Amount' }
        th { 'Donor' }
        th { 'Donee' }
        th { 'Date' }
      end

      @donations.each do |donation|
        tr do
          td { a(href: "/donations/#{donation.id}") { number_to_currency(donation.amount) } }
          td { a(href: "/people/#{donation.donor_id}") { donation.donor.name } }
          td { a(href: "/people/#{donation.donee_id}") { donation.donee.name } }
          td { donation.date.strftime("%m/%d/%Y") }
        end
      end
    end
	end
end