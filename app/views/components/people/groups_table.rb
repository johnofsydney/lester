class People::GroupsTable < ApplicationView
  def initialize(person:, groups:)
    @person = person.cached
    @groups = groups
  end

  attr_reader :person, :groups

  def view_template
    if groups.present?
      div(class: 'row mt-3 mb-3') do
        h4(class: 'font-italic') { 'Groups' }

        render Common::PageNav.new(collection: groups, path: "/people/#{person.id}", param_name: 'groups_page')

        table(class: 'table table-striped responsive-table') do
          tr do
            th { 'Group' }
            th { '(Last) Position' } if groups.any? { |g| g['last_position'].present? }
          end
          groups.each do |group|
            render Common::TableRow.new(hentity: group)
          end
        end
      end
    end
  end
end