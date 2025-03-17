class Common::CollapsibleButtonCollection < ApplicationView
  attr_reader :entity, :exclude_group

	def initialize(entity:, exclude_group: nil)
		@entity = entity
    @exclude_group = exclude_group
	end

	def template
    td(class: 'mobile-display-none', style: 'text-align: right;') do
      if entity.memberships.length == 1 # it me
        ''
      elsif entity.memberships.length < 8
        memberships = entity.memberships - Membership.where(member: entity, group: exclude_group)

        entity.groups.each do |group|
          a(
            href: "/groups/#{group.id}",
            class: 'btn btn-sm',
            style: "#{color_styles(group)}; margin-left: 5px;",
          ) { group.name }
        end
      else
        "#{entity.groups.count} other #{'Group'.pluralize(entity.groups.count)}"

        a(
          href: "/people/#{entity.id}",
          class: 'btn btn-sm',
          style: "#{color_styles(entity)}; margin-left: 5px;",
        ) { "#{entity.groups.count} other #{'Group'.pluralize(entity.groups.count)}" }
      end
    end

    td(class: 'desktop-display-none', style: 'text-align: right;') do
      # "#{entity.groups.count} other #{'Group'.pluralize(entity.groups.count)}"

      a(
        href: "/people/#{entity.id}",
        class: 'btn btn-sm',
        style: "#{color_styles(entity)}; margin-left: 5px;",
      ) { "#{entity.groups.count} other #{'Group'.pluralize(entity.groups.count)}" }
    end

  rescue => e
    puts e.message
    puts e.backtrace
  end
end