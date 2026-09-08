class AdvancedSearch::Query
  ENTITY_CLASSES = { 'Person' => Person, 'Group' => Group }.freeze
  JOINERS = %w[AND OR].freeze
  FACET_TYPES = %w[Category Group].freeze

  Filter = Struct.new(:joiner, :facet_type, :facet_value_ids, keyword_init: true)

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
    scope = scope.where(Arel.sql(filter_conditions)) if filters.any?
    scope.order(:name)
  end

  private

  def entity_class
    ENTITY_CLASSES.fetch(entity_type)
  end

  def build_filters(raw_filters)
    Array(raw_filters).filter_map do |raw|
      facet_value_ids = Array(raw[:facet_value_id]).map(&:presence).compact
      next if facet_value_ids.empty?

      Filter.new(
        joiner: JOINERS.include?(raw[:joiner]) ? raw[:joiner] : 'AND',
        facet_type: FACET_TYPES.include?(raw[:facet_type]) ? raw[:facet_type] : 'Group',
        facet_value_ids: facet_value_ids
      )
    end
  end

  # Folds left-to-right as plain SQL text (rather than SQL's AND-before-OR precedence, so a
  # chain reads the same way it was built) and as string concatenation rather than Arel's
  # .and/.or (which Arel::Nodes::SqlLiteral - the two-hop condition below - doesn't support
  # in this Rails version; mixing it with Arel::Nodes::Exists raised NoMethodError). Every
  # dynamic value is still substituted through sanitize_sql_array before concatenation.
  def filter_conditions
    filters.reduce(nil) do |combined, filter|
      condition = membership_exists(filter)
      next condition if combined.nil?

      "(#{combined} #{filter.joiner} #{condition})"
    end
  end

  # Category+Person matches either a direct Person->Tag membership (e.g. AuLobbyists jobs tag
  # lobbyist individuals straight onto the Lobbyists tag) or the subgroup path below - a person
  # can have one without the other depending on which ingest jobs have run, so both must count.
  def membership_exists(filter)
    if filter.facet_type == 'Category' && entity_type == 'Person'
      "(#{direct_member_of(filter.facet_value_ids)} OR #{person_in_category_via_subgroup(filter.facet_value_ids)})"
    else
      direct_member_of(filter.facet_value_ids)
    end
  end

  # Multiple ids within one row are OR'd via IN (?), e.g. row = "Consulting OR Superannuation".
  def direct_member_of(facet_value_ids)
    sql = 'EXISTS (SELECT 1 FROM memberships WHERE memberships.member_type = ? ' \
          "AND memberships.member_id = #{entity_class.table_name}.id AND memberships.group_id IN (?))"

    Membership.sanitize_sql_array([sql, entity_type, facet_value_ids])
  end

  # Category (Tag) memberships are recorded against sub-groups, not people directly
  # (e.g. state party branches belong to a party Tag; people belong to those branches) -
  # so a Person facet match on a Category needs to go through that intermediate group.
  def person_in_category_via_subgroup(facet_value_ids)
    sql = <<~SQL.squish
      EXISTS (
        SELECT 1 FROM memberships person_memberships
        WHERE person_memberships.member_type = 'Person'
          AND person_memberships.member_id = people.id
          AND EXISTS (
            SELECT 1 FROM memberships subgroup_memberships
            WHERE subgroup_memberships.member_type = 'Group'
              AND subgroup_memberships.member_id = person_memberships.group_id
              AND subgroup_memberships.group_id IN (?)
          )
      )
    SQL

    Membership.sanitize_sql_array([sql, facet_value_ids])
  end
end
