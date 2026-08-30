class Common::PageNav < ApplicationView
  def initialize(collection:, path:, param_name: 'page', extra_params: {})
    @collection = collection
    @path = path
    @param_name = param_name
    @extra_params = extra_params
  end

  def view_template
    return unless total_pages > 1

    nav(aria: { label: 'Page navigation' }) do
      ul(class: 'pagination') do
        previous_page = [current_page - 1, 1].max
        item_class = current_page == 1 ? 'page-item disabled' : 'page-item'
        li(class: item_class) do
          a(class: 'page-link', href: page_href(previous_page)) { 'Previous' }
        end

        pagination_range.each do |page_number|
          item_class = page_number == current_page ? 'page-item active' : 'page-item'
          li(class: item_class) do
            a(class: 'page-link', href: page_href(page_number)) { page_number.to_s }
          end
        end

        next_page = [current_page + 1, total_pages].min
        item_class = current_page == total_pages ? 'page-item disabled' : 'page-item'
        li(class: item_class) do
          a(class: 'page-link', href: page_href(next_page)) { 'Next' }
        end
      end
    end
  end

  private

  attr_reader :collection, :path, :param_name, :extra_params

  def current_page
    collection.current_page
  end

  def total_pages
    collection.total_pages
  end

  def page_href(page_number)
    "#{path}?#{extra_params.merge(param_name => page_number).to_query}"
  end

  def pagination_range
    return (1..total_pages) if total_pages <= 5
    return (1..5) if current_page <= 3
    return ((total_pages - 4)..total_pages) if current_page >= total_pages - 2

    ((current_page - 2)..(current_page + 2))
  end
end
