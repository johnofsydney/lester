class People::IndexView < ApplicationView
  HIGHLIGHT_THRESHOLD = 1883
	def initialize(people:)
		@people = people
	end

	def template
    h1 { 'People' }
    ul do
      @people.each do |person|
        highlight = person.id > HIGHLIGHT_THRESHOLD ? 'highlight-row' : ''
        class_list = "list-group-item list-group-item-action flex-normal #{highlight}"
        div(class: class_list) do
          a(href: "/people/#{person.id}") { person.name }
        end
      end
    end
	end
end