class Groups::AffiliatedGroups < ApplicationView

  attr_reader :group
	def initialize(group:)
		@group = group
	end

  def template

    if group.affiliated_groups.present?
      hr
        h4 { 'Affiliated Groups' }
        ul(class: 'list-group list-group-horizontal', style: 'flex-wrap: wrap;') do
          group.affiliated_groups.each do |group|
            li(class: 'list-group-item horizontal-button') do
              span {a(href: "/groups/#{group.id}") { group.name }}
              span {a(href: "/groups/#{group.id}") { '...' }}
            end
          end
        end
    end
  end
end