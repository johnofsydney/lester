class People::GroupsTable < ApplicationView
  def initialize(person:)
    @person = person.cached
  end

  attr_reader :person

	def template
    groups = person.direct_connections.filter{ |c| c['klass'] == 'Group' }
    if groups.present?
      div(class: 'row mt-3 mb-3') do
        h4(class: 'font-italic') { 'Groups' }

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