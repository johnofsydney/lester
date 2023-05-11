class Groups::ShowView < ApplicationView

  attr_reader :group

	def initialize(group:)
		@group = group
	end

	def template
    div(class: 'col-md-4') do
      div(class: 'card') do
        div(class: 'card-body') do
          a(href: "/groups/#{group.id}", class: 'btn w-100', style: button_styles(group)) { group.name }
        end

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
      end
    end

    a(href: '/groups/new', class: 'btn btn-primary') { 'New Group' }
    a(href: "/groups/#{group.id}/edit", class: 'btn btn-primary') { 'Edit Group' }
    a(href: '/people/', class: 'btn btn-primary') { 'People' }
	end
end