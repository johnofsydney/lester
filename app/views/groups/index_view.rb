class Groups::IndexView < ApplicationView
  HIGHLIGHT_THRESHOLD = 300

	def initialize(groups:, page:, pages:)
		@groups = groups
    @page = page
    @pages = pages
	end

	def template
    h2 { 'Groups' }

    render Common::PageNav.new(pages: @pages, page: @page, klass: 'group')

    @groups.each do |group|
      highlight = group.id > HIGHLIGHT_THRESHOLD ? 'highlight-row' : ''
      class_list = "list-group-item list-group-item-action flex-normal #{highlight}"
      div(class: class_list) do
        a(href: "/groups/#{group.id}") { group.display_name }
        if group.parent_groups.where(category: true).any?
            div do
              group.parent_groups.where(category: true).each do |parent_group|
                a(
                  href: "/groups/#{parent_group.id}",
                  class: 'btn btn-sm',
                  style: "#{color_styles(parent_group)}; margin-left: 5px;",
                ) { parent_group.name }
              end
            end
        end
      end
    end

    render Common::PageNav.new(pages: @pages, page: @page, klass: 'group')
	end
end