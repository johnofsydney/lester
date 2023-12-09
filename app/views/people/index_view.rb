class People::IndexView < ApplicationView
	def initialize(people:)
		@people = people
	end

	def template
    render MenuComponent.new(new: {path: '/people/new', text: 'New Person'})

		h1 { 'People' }
    ul do
      @people.each do |person|
        li do
          a(href: "/people/#{person.id}") { person.name }
        end
      end
    end
	end
end