class Donations::ShowView < ApplicationView

  attr_reader :donation

	def initialize(donation:)
		@donation = donation
	end

	def template
    div(class: 'col-md-4') do
      div(class: 'card') do
        div(class: 'card-body') do
          a(href: "/donations/#{donation.id}", class: 'btn w-100', style: button_styles(donation)) { donation.amount.to_s }
          a(href: "/donations/#{donation.donor_id}", class: 'btn w-100', style: button_styles(donation)) { donation.donor.name.to_s }
          a(href: "/donations/#{donation.donee_id}", class: 'btn w-100', style: button_styles(donation)) { donation.donee.name.to_s }
        end

        # group.people.each do |person|
        #   div(class: 'list-group-item flex-normal') do
        #     div do
        #       a(href: "/people/#{person.id}", class: 'btn-primary btn', style: button_styles(person)) { person.name }
        #     end
        #     div do
        #       person.groups.each do |group|
        #         a(href: "/groups/#{group.id}", class: 'btn-secondary btn btn-sml', style: button_styles(group) ) { group.name }
        #       end
        #     end
        #   end
        # end
      end
    end

    a(href: '/groups/', class: 'btn btn-primary') { 'Groups' }
    a(href: '/donations/', class: 'btn btn-primary') { 'Donations' }

    a(href: '/people/', class: 'btn btn-primary') { 'People' }
	end
end