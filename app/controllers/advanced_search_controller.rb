class AdvancedSearchController < ApplicationController
  MIN_TERM_LENGTH = 2
  MAX_RESULTS = 20
  SIMILARITY_THRESHOLD = 0.4

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
