class AdvancedSearchController < ApplicationController
  def index
    @query = AdvancedSearch::Query.new(
      entity_type: search_params[:entity_type],
      filters: Array(search_params[:filters]).map(&:to_h),
      name: search_params[:name]
    )
    @results = @query.searchable? ? @query.call.page(params[:page]) : nil

    @tags = Tag.order(:name)
    @group_facet_names = Group.where(id: @query.filters.select { |f| f.facet_type == 'Group' }.map(&:facet_value_id))
                               .pluck(:id, :name).to_h
  end

  def group_autocomplete
    term = params[:term].to_s.strip
    groups = term.length < 2 ? [] : matching_groups(term)

    render json: groups.map { |row| { id: row['id'], name: Nodes::NameCapitalizer.capitalize(row['name']) } }
  end

  private

  def search_params
    params.permit(:entity_type, :name, filters: %i[joiner facet_type facet_value_id])
  end

  def matching_groups(term)
    sql = ActiveRecord::Base.sanitize_sql_array([
      'SELECT id, name FROM groups WHERE name % :term ORDER BY similarity(name, :term) DESC LIMIT 10',
      term: term
    ])
    ActiveRecord::Base.connection.exec_query(sql).to_a
  end
end
