class People::Groups < ApplicationView
	def initialize(groups:, person:)
		@groups = groups
    @person = person
	end

  attr_reader :groups, :person

	def template
    div(class: 'row') do
      h2 { 'Groups' }

      groups.each do |group|
        render People::Group.new(group: group, exclude_person: person)
      end
    end
  end
end