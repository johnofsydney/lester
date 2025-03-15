class Groups::PeopleTable < ApplicationView
  include Constants

	def initialize(people: nil, exclude_group: nil, page: nil, pages: nil)
    @people = people
    @exclude_group = exclude_group
    @page = page
    @pages = pages
	end

  attr_reader :people, :exclude_group, :page, :pages

  def template
    turbo_frame(id: 'people') do
      if people.present?
        div(class: 'row mt-3 mb-3') do
          h4(class: 'font-italic') { 'People' }

          page_nav

          table(class: 'table table-striped responsive-table') do
            tr do
              th { 'Person' }
              th { '(Last) Position' }
              th { 'Other Groups' }
            end
            people.each do |person|
              render Groups::PersonTableRow.new(person:, exclude_group:)
            end
          end
        end
      end
    end
  end

  def page_nav
    # TODO: Adapt and use Common::PageNav
    return if pages < 2

    nav(aria: { label: "Page navigation example" }) do
      ul(class: "pagination") do
        previous_page = @page - 1
        item_class = @page == 0 ? "page-item disabled" : "page-item"
        li(class: item_class) do
          a(class: "page-link", href: "/groups/group_people/#{exclude_group.id}/page=#{previous_page}") { "Previous" }
        end

        pagination_range.each do |page_number|
          item_class = page_number == @page ? "page-item active" : "page-item"
          li(class: item_class) do
            a(
              class: "page-link",
              href: "/groups/group_people/#{exclude_group.id}/page=#{page_number}"
              ) do
              page_number + 1
            end
          end
        end

        next_page = @page + 1
        item_class = next_page == pages ? "page-item disabled" : "page-item"
        li(class: item_class) do
          a(class: "page-link", href: "/groups/group_people/#{exclude_group.id}/page=#{next_page}") { "Next" }
        end
      end
    end
  end

  def pagination_range
    return (0...pages) if pages < 5
    return (0..4) if @page < 3
    return ((pages - 5)...pages) if @page > pages - 3

    ((@page - 2)..(@page + 2))
  end
end
