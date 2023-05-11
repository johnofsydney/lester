class People::EditView < ApplicationView
	def initialize(person:)
		@person = person
	end

	def template
    h1 { 'Editing Person' }

    form(action: "/people/#{@person[:id]}", method: 'post') do
      input(type: 'hidden', name: '_method', value: 'patch')
      input(type: 'hidden', name: 'person[id]', value: @person[:id])
      label(for: 'person_name') { 'Name' }
      input(type: 'text', name: 'person[name]', value: @person[:name])
      button(type: 'submit') { 'Update Person' }


      h2 { 'Current Groups' }
      ul do
        @person.groups.each do |group|
          li { group.name }
        end
      end

      select(class: 'form-control', name: 'person[group_ids][]', multiple: true) do
        option(value: '') { ' ' }
        Group.all.each do |group|
          option(value: group.id, selected: @person.group_ids.include?(group.id)) { group.name }
        end
      end
    end

    a(href: '/groups/', class: 'btn btn-secondary') { 'Groups' }
    a(href: '/people/', class: 'btn btn-secondary') { 'People' }
	end
end
