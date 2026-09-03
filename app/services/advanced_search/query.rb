class AdvancedSearch::Query
  ENTITY_CLASSES = { 'Person' => Person, 'Group' => Group }.freeze
  JOINERS = %w[AND OR].freeze
  FACET_TYPES = %w[Category Group].freeze

  Filter = Struct.new(:joiner, :facet_type, :facet_value_id, keyword_init: true)

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
        facet_type: FACET_TYPES.include?(raw[:facet_type]) ? raw[:facet_type] : 'Group',
        facet_value_id: facet_value_id
      )
    end
  end

  # Folds filters left-to-right rather than relying on SQL's AND-before-OR
  # precedence, so a chain reads the same way it was built, top to bottom.
  def filter_conditions
    filters.reduce(nil) do |combined, filter|
      condition = membership_exists(filter)
      next condition if combined.nil?

      filter.joiner == 'AND' ? combined.and(condition) : combined.or(condition)
    end
  end

  def membership_exists(filter)
    if filter.facet_type == 'Category' && entity_type == 'Person'
      person_in_category_via_subgroup(filter.facet_value_id)
    else
      direct_member_of(filter.facet_value_id)
    end
  end

  def direct_member_of(facet_value_id)
    Membership.where(
      'memberships.member_type = ? AND memberships.member_id = ' \
      "#{entity_class.table_name}.id AND memberships.group_id = ?",
      entity_type, facet_value_id
    ).arel.exists
  end

  # Category (Tag) memberships are recorded against sub-groups, not people directly
  # (e.g. state party branches belong to a party Tag; people belong to those branches) -
  # so a Person facet match on a Category needs to go through that intermediate group.
  def person_in_category_via_subgroup(facet_value_id)
    sql = <<~SQL.squish
      EXISTS (
        SELECT 1 FROM memberships person_memberships
        WHERE person_memberships.member_type = 'Person'
          AND person_memberships.member_id = people.id
          AND EXISTS (
            SELECT 1 FROM memberships subgroup_memberships
            WHERE subgroup_memberships.member_type = 'Group'
              AND subgroup_memberships.member_id = person_memberships.group_id
              AND subgroup_memberships.group_id = ?
          )
      )
    SQL

    Arel.sql(Membership.sanitize_sql_array([sql, facet_value_id]))
  end
end
