class People::IndexView < Phlex::HTML
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

    a(href: '/people/new') { 'New Person' }
	end
end