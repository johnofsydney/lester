class Groups::People < ApplicationView
	def initialize(people:, group: nil)
		@people = people
    @group = group
	end

  attr_reader :people, :group

	def template
    div(class: 'row') do
      h2 { 'People' }

      people.each do |person|
        render Groups::Person.new(person:, exclude_group: group)
      end
    end
  end
end