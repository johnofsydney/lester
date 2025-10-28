class Groups::EditView < ApplicationView
	def initialize(group:)
		@group = group
	end

	def view_template
    h1 { 'Editing Group' }

    form(action: "/groups/#{@group[:id]}", method: 'post') do
      input(type: 'hidden', name: '_method', value: 'patch')
      input(type: 'hidden', name: 'group[id]', value: @group[:id])
      label(for: 'group_name') { 'Name' }
      input(type: 'text', name: 'group[name]', value: @group[:name])
      button(type: 'submit') { 'Update Group' }

      h2 { 'Current People' }
      ul do
        @group.people.each do |person|
          li { person.name }
        end
      end

      select(class: 'form-control', name: 'group[people_ids][]', multiple: true) do
        option(value: '') { ' ' }
        People.find_each do |person|
          option(value: person.id, selected: @group.person_ids.include?(person.id)) { person.name }
        end
      end
    end

    a(href: '/groups/', class: 'btn btn-secondary') { 'Groups' }
    a(href: '/people/', class: 'btn btn-secondary') { 'People' }
	end
end
