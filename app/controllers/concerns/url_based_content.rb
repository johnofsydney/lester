module UrlBasedContent
  extend ActiveSupport::Concern

  included do
    before_action :set_url_based_content
  end

  private

  def set_url_based_content
    @current_path = request.path
    @current_url = request.url
    @query_params = request.query_parameters

    Current.host = request.url


    # Set content based on URL patterns
    case @current_path
    when '/search'
      setup_search_page
    when '/people'
      setup_people_page
    when '/groups'
      setup_groups_page
    when %r{^/people/\d+}
      setup_person_detail_page
    end
  end

  def setup_search_page
    @page_title = "Search"
    @body_classes = "search-page"
    @custom_css = "
      .search-page { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
      .search-form { border: 2px solid #4a5568; }
    "
  end

  def setup_people_page
    @page_title = "People Directory"
    @body_classes = "people-index"
    @custom_css = ".people-index { background-color: #f7fafc; }"
  end

  def setup_groups_page
    @page_title = "Groups Directory"
    @body_classes = "groups-index"
  end

  def setup_person_detail_page
    @body_classes = "person-detail"
    @custom_css = ".person-detail { padding: 40px; }"
  end
end