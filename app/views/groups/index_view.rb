class Groups::IndexView < ApplicationView
	def initialize(groups:, page:)
		@groups = groups
    @page = page
	end

	def template
    h2 { 'Groups' }

    page_nav

    @groups.each do |group|
      class_list = group.id > 1640 ? 'class: list-group-item list-group-item-action flex-normal highlight-row' : 'class: list-group-item list-group-item-action flex-normal'
      div(class: class_list) do
        a(href: "/groups/#{group.id}") { "#{group.name} - #{group.business_number}" }
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

    page_nav
	end

  def page_nav
    nav(aria: { label: "Page navigation example" }) do
      ul(class: "pagination") do

        previous_page = @page - 1 < 1 ? 1 : @page - 1
        a(class: "page-link", href: "/groups/page=#{previous_page}") { "<<" }

        Group.where(category: false).order(:name).each_slice(250).to_a.each_with_index do |groups, index|
          li(class: "page-item") do
            page_number = index + 1

            a(class: "page-link", href: "/groups/page=#{page_number}") do
              page_number
            end
          end
        end

        next_page = @groups.count < 250 ? @page : @page + 1
        a(class: "page-link", href: "/groups/page=#{next_page}") { ">>" }

      end
    end
  end
end