class Groups::IndexView < ApplicationView
	def initialize(groups:)
		@groups = groups
	end

	def template
    h1 { 'Groups' }
    ul do
      @groups.sort_by { |group| group.nodes.count }.reverse.each do |group|
        li do
          a(href: "/groups/#{group.id}") { group.name }
        end
      end
    end
	end
end