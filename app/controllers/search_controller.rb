class SearchController < ApplicationController
  def index
    @search_term = params[:query]
    @results = PgSearch.multisearch(@search_term).page(params[:page])

    # Feeds the additive advanced-search widget rendered on this same page.
    @advanced_query = AdvancedSearch::Query.new(entity_type: 'Person')
    @tags = Tag.order(:name)
    @group_facet_names = {}
  end
end
