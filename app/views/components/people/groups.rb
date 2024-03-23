class People::Groups < ApplicationView
	def initialize(groups:, person:)
		@groups = groups.sort_by { |group| group.memberships.count }.reverse
    @person = person
	end

  attr_reader :groups, :person

	def template
    div(class: 'row') do
      h2 { 'Groups' }

      table(class: 'table') do
        tr do
          th { 'Group' }
          th { 'Position' }
          th { 'Other Members' }
        end
        groups.each do |group|
          render People::Group.new(group: group, exclude_person: person)
        end
      end

    end
  end
end