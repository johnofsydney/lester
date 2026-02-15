class People::IndexView < ApplicationView
  def initialize(people:, page:, pages:)
    @people = people
    @page = page
    @pages = pages
  end

  def view_template
    div(class: 'mt-3 mb-3') do
      h2 { 'People' }

      render Common::PageNav.new(pages:, page:, klass: 'person')

      div(class: 'list-group') do
        people.each do |person|
          class_list = 'list-group-item list-group-item-action flex-normal'
          div(class: class_list) do
            person_name_link(person)

            # TODO: this is usning un-cached data - decide whether to keep it
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
  end

  private

  attr_reader :people, :page, :pages

  def person_name_link(person)
    link_for(
      entity: person,
      class: 'desktop-only',
      link_text: person.name.truncate(100)
    )

    link_for(
      entity: person,
      class: 'mobile-only',
      link_text: person.name.truncate(50)
    )
  end
end
