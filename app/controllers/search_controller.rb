class SearchController < ApplicationController
  include UrlBasedContent

  def index
    search_term = params[:query]
    @results = PgSearch.multisearch(search_term)
  end
end
