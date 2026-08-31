class AdvancedSearch::Query
  ENTITY_CLASSES = { 'Person' => Person, 'Group' => Group }.freeze
  FACET_TYPES = %w[Category Group].freeze
  JOINERS = %w[AND OR].freeze
  MAX_FILTERS = 10

  Filter = Struct.new(:joiner, :facet_type, :facet_value_id, keyword_init: true)

  def self.call(entity_type:, filters: [], name: nil)
    new(entity_type: entity_type, filters: filters, name: name).call
  end

  def initialize(entity_type:, filters: [], name: nil)
    @entity_type = ENTITY_CLASSES.key?(entity_type) ? entity_type : 'Person'
    @filters = build_filters(filters)
    @name = name.presence
  end

  attr_reader :entity_type, :filters, :name

  def call
    scope = entity_class.all
    scope = scope.where(filter_conditions_sql) if filters.any?
    scope = scope.where('name ILIKE ?', "%#{sanitize_ilike(name)}%") if name.present?
    scope.order(:name)
  end

  # True once the user has picked at least one facet or a name-within-results term -
  # used by the controller to decide whether to run the query or just show the empty form.
  def searchable?
    filters.any? || name.present?
  end

  private

  def entity_class
    ENTITY_CLASSES.fetch(entity_type)
  end

  def build_filters(raw_filters)
    Array(raw_filters).first(MAX_FILTERS).filter_map do |raw|
      facet_value_id = raw[:facet_value_id].presence
      next if facet_value_id.blank?

      Filter.new(
        joiner: JOINERS.include?(raw[:joiner]) ? raw[:joiner] : 'AND',
        facet_type: FACET_TYPES.include?(raw[:facet_type]) ? raw[:facet_type] : 'Category',
        facet_value_id: facet_value_id.to_i
      )
    end
  end

  # Folds filters left-to-right (rather than relying on SQL's AND-before-OR precedence) so
  # "Lobbyist OR Charity AND NSW Parliament" reads the same way the user built it, top to bottom.
  def filter_conditions_sql
    filters.reduce(nil) do |acc, filter|
      fragment = membership_exists_sql(filter)
      acc.nil? ? fragment : "(#{acc} #{filter.joiner} #{fragment})"
    end
  end

  # facet_type ("Category" vs "Group") only decides which selector the UI showed for this row -
  # a Tag id and a plain Group id both live in `groups.id`, so the membership check is identical.
  def membership_exists_sql(filter)
    sql = 'EXISTS (SELECT 1 FROM memberships WHERE memberships.member_type = ? ' \
          "AND memberships.member_id = #{entity_class.table_name}.id AND memberships.group_id = ?)"

    ActiveRecord::Base.sanitize_sql_array([sql, entity_type, filter.facet_value_id])
  end

  def sanitize_ilike(term)
    term.gsub(/[%_\\]/) { |char| "\\#{char}" }
  end
end
