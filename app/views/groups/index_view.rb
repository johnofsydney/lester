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

    a(href: '/groups/new', class: 'btn btn-primary') { 'New Group' }
    a(href: '/people/', class: 'btn btn-secondary') { 'People' }
	end
end