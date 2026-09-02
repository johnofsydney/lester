class AdvancedSearchController < ApplicationController
  MIN_TERM_LENGTH = 2
  MAX_RESULTS = 20
  SIMILARITY_THRESHOLD = 0.4

  def index
    @entity_type = AdvancedSearch::Query::ENTITY_CLASSES.key?(params[:entity_type]) ? params[:entity_type] : 'Person'
    @filters = Array(params[:filters]).map(&:to_unsafe_h)
    @searched = @filters.any? { |filter| filter[:facet_value_id].present? }

    @results = AdvancedSearch::Query.new(entity_type: @entity_type, filters: @filters).call.page(params[:page]) if @searched
  end

  def group_autocomplete
    term = params[:q].to_s.strip

    groups = term.length < MIN_TERM_LENGTH ? Group.none : matching_groups(term)

    render json: groups.map { |group| { id: group.id, name: Nodes::NameCapitalizer.capitalize(group.name) } }
  end

  private

  def matching_groups(term)
    Group.where(Group.sanitize_sql_array(['strict_word_similarity(?, name) >= ?', term, SIMILARITY_THRESHOLD]))
         .order(Arel.sql(Group.sanitize_sql_array(['strict_word_similarity(?, name) DESC', term])))
         .limit(MAX_RESULTS)
  end
end
