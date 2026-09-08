class AdvancedSearch::Query
  ENTITY_CLASSES = { 'Person' => Person, 'Group' => Group }.freeze
  JOINERS = %w[AND OR].freeze

  Filter = Struct.new(:joiner, :facet_value_id, keyword_init: true)

  def self.call(entity_type:, filters: [])
    new(entity_type: entity_type, filters: filters).call
  end

  def initialize(entity_type:, filters: [])
    @entity_type = entity_type
    @filters = build_filters(filters)
  end

  attr_reader :entity_type, :filters

  def call
    scope = entity_class.all
    scope = scope.where(filter_conditions) if filters.any?
    scope.order(:name)
  end

  private

  def entity_class
    ENTITY_CLASSES.fetch(entity_type)
  end

  def build_filters(raw_filters)
    Array(raw_filters).filter_map do |raw|
      facet_value_id = raw[:facet_value_id]
      next if facet_value_id.blank?

      Filter.new(
        joiner: JOINERS.include?(raw[:joiner]) ? raw[:joiner] : 'AND',
        facet_value_id: facet_value_id
      )
    end
  end

  # Folds filters left-to-right rather than relying on SQL's AND-before-OR
  # precedence, so a chain reads the same way it was built, top to bottom.
  def filter_conditions
    filters.reduce(nil) do |combined, filter|
      condition = membership_exists(filter.facet_value_id)
      next condition if combined.nil?

      filter.joiner == 'AND' ? combined.and(condition) : combined.or(condition)
    end
  end

  def membership_exists(facet_value_id)
    Membership.where(
      'memberships.member_type = ? AND memberships.member_id = ' \
      "#{entity_class.table_name}.id AND memberships.group_id = ?",
      entity_type, facet_value_id
    ).arel.exists
  end
end
