class People::ShowView < ApplicationView

  attr_reader :person

	def initialize(person:)
		@person = person
	end

	def template
    div(class: 'col-md-4') do
      div(class: 'card') do
        div(class: 'card-body') do
          a(href: "/people/#{person.id}", class: 'btn w-100', style: button_styles(person)) { person.name }
        end

        person.groups.each do |group|
          div(class: 'list-group-item flex-normal') do
            div do
              a(href: "/groups/#{group.id}", class: 'btn-primary btn', style: button_styles(group)) { group.name }
            end
            div do
              group.people.each do |person|
                a(href: "/people/#{person.id}", class: 'btn-secondary btn btn-sml', style: button_styles(person) ) { person.name }
              end
            end
          end
        end
      end
    end

    # main menu
    span { strong { 'see also footer' } }
    a(href: '/groups/', class: 'btn btn-primary') { 'Groups' }
    a(href: '/transactions/', class: 'btn btn-primary') { 'Transactions' }
    a(href: '/people/', class: 'btn btn-primary') { 'People' }
    a(href: '/imports/annual_donor/', class: 'btn btn-primary') { 'TEMP | IMPORT DONATIONS' }

    a(href: '/people/new', class: 'btn btn-primary') { 'New Person' }
    a(href: "/people/#{person.id}/edit", class: 'btn btn-primary') { 'Edit Person' }
	end
end
