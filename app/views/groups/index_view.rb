class Groups::IndexView < ApplicationView
	def initialize(groups:)
		@groups = groups
	end

	def template
    render MenuComponent.new(new: {path: '/groups/new', text: 'New Group'})

		h1 { 'Groups' }
    ul do
      @groups.sort_by { |group| group.nodes.count }.reverse.each do |group|
        li do
          a(href: "/groups/#{group.id}") { group.name }
        end
      end
    end

    a(href: '/groups/new', class: 'btn btn-primary') { 'New Group' }
    a(href: '/groups/', class: 'btn btn-primary') { 'Groups' }
    a(href: '/people/', class: 'btn btn-secondary') { 'People' }
    a(href: '/donations/', class: 'btn btn-secondary') { 'Donations' }
	end
end