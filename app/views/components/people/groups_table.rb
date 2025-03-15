class People::GroupsTable < ApplicationView
	def initialize(groups:, person:)
		@groups = groups.sort_by { |group| group.memberships.count }.reverse
    @person = person
	end

  attr_reader :groups, :person

	def template
    if person.groups.present?
      div(class: 'row mt-3') do
        h4(class: 'font-italic') { 'Groups' }

        table(class: 'table table-striped responsive-table') do
          tr do
            th { 'Group' }
            th { '(Last) Position' }
            th { 'Other Members' }
          end
          groups.each do |group|
            render People::GroupTableRow.new(group: group, exclude_person: person)
          end
        end

      end
    end
  end
end