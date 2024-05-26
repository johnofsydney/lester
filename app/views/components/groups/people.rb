class Groups::People < ApplicationView
	def initialize(group: nil)
    @people = group.people.sort_by { |person| person.memberships.count }.reverse
    @group = group
	end

  attr_reader :people, :group

	def template
    if people.present?
      hr
        div(class: 'row') do
        h2 { 'People' }

        table(class: 'table table-striped responsive-table') do
          tr do
            th { 'Person' }
            th { 'Position' }
            th { 'Other Groups' }
          end
          people.each do |person|
            render Groups::Person.new(person:, exclude_group: group)
          end
        end
      end
    end
  end
end
