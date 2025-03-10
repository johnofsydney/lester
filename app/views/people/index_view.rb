class People::IndexView < ApplicationView
  HIGHLIGHT_THRESHOLD = 1883
	def initialize(people:, page:, pages:)
		@people = people
    @page = page
    @pages = pages
	end

	def template
    h2 { 'People' }

    render Common::PageNav.new(pages:, page:, klass: 'person')

    people.each do |person|
      highlight = if Flipper.enabled?(:dev_highlighting)
        person.id > HIGHLIGHT_THRESHOLD ? 'highlight-row' : ''
      else
        ''
      end

      class_list = "list-group-item list-group-item-action flex-normal #{highlight}"
      div(class: class_list) do
        a(href: "/people/#{person.id}") { person.name }
        if person.groups.any?
          div do
            person.groups.each do |group|
              a(
                href: "/groups/#{group.id}",
                class: 'btn btn-sm',
                style: "#{color_styles(group)}; margin-left: 5px;",
              ) { group.name }
            end
          end
        end
      end
    end
	end

  private

  attr_reader :people, :page, :pages
end