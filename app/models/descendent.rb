# NOTE this class is NOT backed by a table. It does NOT inherit from ActiveRecord
# It is a simple data object that holds data from the node, used for display
# in the network graph, and as part of the tables created using consildated_descendents

class Descendent
  attr_accessor :entity, :id, :name, :depth, :klass, :parent, :parent_count

  def initialize(node: nil, id: nil, name: nil, klass: nil, depth:, parent: nil, parent_count: nil)
    @entity = node # this is the entity; Person or Group
    @id = node&.id || id
    @name = node&.name || name
    @depth = depth
    @klass = node&.class&.to_s || klass
    @parent = parent
    @parent_count = parent_count
  end

  def shape
    return 'circle' if depth.zero?
    return 'dot' if member_of_large_group?

    klass == 'Person' ? 'dot' : 'box'
  end

  def color
    # https://chartscss.org/components/colors/
    case depth
    when 0
      'rgba(240,50,50,1)'
    when 1
      'rgba(255,180,50,1)'
    when 2
      'rgba(100,210,80,1)'
    when 3
      'rgba(90,165,255,1)'
    when 4
      'rgba(170,90,240,1)'
    when 5
      'rgba(180,180,180,1)'
    when 6
    end
  end

  def mass
    return 2 if klass == 'Person'

    case parent_size
    when 0..3
      4
    when 4..6
      6
    when 7..10
      8
    when 11..15
      10
    else
      12
    end
  end

  def size
    return 35 if depth.zero?
    return 5 if klass == 'Person'
  end

  def url
    klass_name_plural = klass.to_s.pluralize.downcase

    "/#{klass_name_plural}/#{id}"
  end

  private

  def member_of_large_group?
    return unless parent_count || parent

    count = parent_count || parent&.nodes_count || 0

    klass == 'Person' && count > 15
  end

  def parent_size
    return 0 unless parent_count || parent

    count = parent_count || parent&.nodes_count || 0
  end
end