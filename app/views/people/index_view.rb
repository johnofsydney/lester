class People::IndexView < ApplicationView
	def initialize(people:)
		@people = people
	end

	def template
		h1 { 'People' }
    ul do
      @people.each do |person|
        li do
          a(href: "/people/#{person.id}") { person.name }
        end
      end
    end

    a(href: '/people/new', class: 'btn btn-primary') { 'New Person' }
    a(href: '/groups/', class: 'btn btn-secondary') { 'Groups' }
	end
end