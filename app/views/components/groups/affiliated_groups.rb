class Groups::AffiliatedGroups < ApplicationView
	def initialize(groups:)
		@groups = groups
	end

  attr_reader :groups

	def template
    div(class: 'row') do
      h2 { 'Affiliated Groups' }

      groups.each do |group|
        render Groups::AffiliatedGroup.new(group: group)
      end
    end
  end
end