class AdvancedSearchController < ApplicationController
  MIN_TERM_LENGTH = 2
  MAX_RESULTS = 20

  def index
    @entity_type = AdvancedSearch::Query::ENTITY_CLASSES.key?(params[:entity_type]) ? params[:entity_type] : 'Person'
    @filters = Array(params[:filters]).map(&:to_unsafe_h)
    @searched = @filters.any? { |filter| Array(filter[:facet_value_id]).any?(&:present?) }

    @results = AdvancedSearch::Query.new(entity_type: @entity_type, filters: @filters).call.page(params[:page]) if @searched
  end

  def group_autocomplete
    term = params[:q].to_s.strip

    groups = term.length < MIN_TERM_LENGTH ? Group.none : Group.matching_name(term).limit(MAX_RESULTS)

    render json: groups.map { |group| { id: group.id, name: Nodes::NameCapitalizer.capitalize(group.name) } }
  end
end
