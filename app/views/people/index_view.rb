class People::IndexView < ApplicationView
  HIGHLIGHT_THRESHOLD = 1914

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

      div(class: 'list-group') do
        class_list = "list-group-item list-group-item-action flex-normal #{highlight}"
        div(class: class_list) do
          a(href: "/people/#{person.id}") { person.name }

          render Common::CollapsibleButtonCollection.new(
            collection: person.groups,
            entity: person,
            render_inside: 'div'
          )

        end
      end
    end

    render Common::PageNav.new(pages:, page:, klass: 'person')
	end

  private

  attr_reader :people, :page, :pages
end