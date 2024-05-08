class Groups::IndexView < ApplicationView
	def initialize(groups:)
		@groups = groups
	end

	def template
    h1 { 'Groups' }
    ul do
      @groups.each do |group|
        li do
          a(href: "/groups/#{group.id}") { group.name }
        end
      end
    end
	end
end