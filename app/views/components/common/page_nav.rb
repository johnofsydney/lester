class Common::PageNav < ApplicationView
  attr_reader :pages

  def initialize(pages:, page:, klass:)
    @page = page
    @klass = klass
    @pages = pages
  end

  def template
    return unless pages > 1

    nav(aria: { label: 'Page navigation example' }) do
      ul(class: 'pagination') do

        previous_page = [@page - 1, 1].max
        item_class = @page == 0 ? 'page-item disabled' : 'page-item'
        li(class: item_class) do
          a(class: 'page-link', href: "/#{@klass.pluralize}/page=#{previous_page}") { 'Previous' }
        end

        pagination_range.each do |index|
          li(class: 'page-item') do
            page_number = index + 1
            return if page_number > pages

            a(class: 'page-link', href: "/#{@klass.pluralize}/page=#{page_number}") do
              page_number
            end
          end
        end

        next_page = @page + 1
        item_class = (next_page >= pages) ? 'page-item disabled' : 'page-item'
        li(class: item_class) do
          a(class: 'page-link', href: "/#{@klass.pluralize}/page=#{next_page}") { 'Next' }
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