class Groups::IndexView < Phlex::HTML
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

    a(href: '/groups/new') { 'New Group' }
	end
end