class Groups::PeopleTable < ApplicationView
  include Constants

	 def initialize(people: nil, exclude_group: nil, page: nil, pages: nil)
     # leaving pagination related args in place for now. exclude_group is better named as current_group
     @people = people
     @exclude_group = exclude_group
     @page = page
     @pages = pages
 	end

  attr_reader :people, :exclude_group, :page, :pages

  def view_template
    turbo_frame(id: 'people') do
      if people.present?
        div(class: 'row mt-3 mb-3') do
          h4(class: 'font-italic') { 'People' }

          # TODO: wire up Common::PageNav here (pagination re-enabled in a follow-up PR)

          table(class: 'table table-striped responsive-table') do
            tr do
              th { 'Person' }
              th { '(Last) Position' }
            end
            people.each do |person|
              render Common::TableRow.new(hentity: person)
            end
          end
        end
      end
    end
  end
end
