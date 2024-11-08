class Groups::PeopleTable < ApplicationView
  include Constants

	def initialize(people: nil, exclude_group: nil, page: nil)
    @people = people
    @exclude_group = exclude_group
    @page = page
	end

  attr_reader :people, :exclude_group, :page

  def template
    turbo_frame(id: 'people') do
      if people.present?
        hr
        h4 { 'People' }


        page_nav

        table(class: 'table table-striped responsive-table') do
          tr do
            th { 'Person' }
            th { '(Last) Position' }
            th { 'Other Groups' }
          end
          people.each do |person|
            render Groups::Person.new(person:, exclude_group:)
          end
        end
      end
    end
  end

  def page_nav
    return if people.count < Constants::VIEW_TABLE_LIST_LIMIT

    nav(aria: { label: "Page navigation example" }) do
      ul(class: "pagination") do

        previous_page = @page - 1 < 1 ? 1 : @page - 1
        a(class: "page-link", href: "/groups/group_people/#{exclude_group.id}/page=#{previous_page}") { "<<" }

        people.order(:name).each_slice(Constants::VIEW_TABLE_LIST_LIMIT).to_a.each_with_index do |groups, index|
          li(class: "page-item") do
            page_number = index + 1

            a(
              class: "page-link",
              href: "/groups/group_people/#{exclude_group.id}/page=#{page_number}"
              ) do
              page_number
            end
          end
        end

        next_page = @people.count < Constants::VIEW_TABLE_LIST_LIMIT ? @page : @page + 1
        a(class: "page-link", href: "/groups/group_people/#{exclude_group.id}/page=#{next_page}") { ">>" }

      end
    end
  end
end