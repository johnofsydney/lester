class Donations::SummaryView < ApplicationView
  include ActionView::Helpers::NumberHelper

	def initialize(summaries:)
		@summaries = summaries
	end

	def template
		h1 { 'donations summary' }

    table(class: 'table') do
      tr do
        th { 'Amount' }
        th { 'Donor' }
        th { 'Donee' }
      end

      @summaries.each do |summary|
        type = summary.donor_type
        donor_id = summary.donor_id
        donor = type.constantize.find(donor_id)

        donee = Group.find(summary.donee_id)

        amount = Donation.where(donor_id: donor.id, donee_id: donee.id).pluck(:amount).sum
        tr do
          td { number_to_currency(amount) }
          td { a(href: "/people/#{summary.donor_id}") { donor.name } }
          td { a(href: "/people/#{summary.donee_id}") { donee.name } }
        end
      end
    end
	end
end