class Groups::People < ApplicationView
	def initialize(people:, group: nil)
		@people = people
    @group = group
	end

  attr_reader :people, :group

	def template
    # TODO: look at card-coluns class
    # https://getbootstrap.com/docs/4.0/components/card/#card-columns
    div(class: 'row') do
      h2 { 'People' }

      table(class: 'table') do
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