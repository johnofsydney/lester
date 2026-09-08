class AdvancedSearchController < ApplicationController
  MIN_TERM_LENGTH = 2
  MAX_RESULTS = 20

  # Matches the duck-typed shape SearchResults (used by the simple search results view) expects,
  # so the two search modes render results identically without coupling it to PgSearch::Document.
  SearchResultRow = Struct.new(:searchable_type, :searchable_id, :content)

  def index
    @entity_type = AdvancedSearch::Query::ENTITY_CLASSES.key?(params[:entity_type]) ? params[:entity_type] : 'Person'
    @filters = Array(params[:filters]).filter_map { |filter| filter.to_unsafe_h if filter.respond_to?(:to_unsafe_h) }
    @submitted = params[:entity_type].present?
    @searched = @filters.any? { |filter| Array(filter[:facet_value_id]).any?(&:present?) }

    @results = AdvancedSearch::Query.new(entity_type: @entity_type, filters: @filters).call.page(params[:page]) if @searched
  end

  def group_autocomplete
    term = params[:q].to_s.strip

    groups = term.length < MIN_TERM_LENGTH ? Group.none : Group.matching_name(term).limit(MAX_RESULTS)

    render json: groups.map { |group| { id: group.id, name: Nodes::NameCapitalizer.capitalize(group.name) } }
  end
end
