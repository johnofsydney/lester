# NOTE: this class is NOT backed by a table. It does NOT inherit from ActiveRecord
# It is a simple data object that holds data from the node, used for display
# in the network graph, and as part of the tables created using consolidated_descendents

class Descendent
  attr_accessor :entity, :id, :name, :depth, :klass, :parent, :parent_count

  def initialize(depth:, node: nil, id: nil, name: nil, klass: nil, parent: nil, parent_count: nil)
    @entity = node # this is the entity; Person or Group
    @id = node&.id || id
    @name = node&.name || name
    @depth = depth
    @klass = node&.class&.to_s || klass
    @parent = parent
    @parent_count = parent_count
  end

  def to_h
    {
      parent_id: parent&.id,
      parent_name: parent&.name,
      parent_klass: parent&.class&.to_s,
      parent_count: parent_count || parent_size,
      id:,
      name:,
      klass:,
      depth:,
      shape:,
      color:,
      mass:,
      size:,
      url:,
      last_position: last_position(parent, entity),
      is_tag: entity.is_a?(Group) ? entity.is_tag? : false
    }
  end

  def shape
    return 'circle' if depth.zero?

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
    # box does not appear to respond to size
    if depth.zero?
      35
    elsif klass == 'Person'
      5
    end
  end

  def url
    klass_name_plural = klass.to_s.pluralize.downcase

    "/#{klass_name_plural}/#{id}"
  end

  private

  def parent_size
    return 0 unless parent_count || parent

    parent_count || parent&.nodes_count || 0
  end

  def last_position(node, entity)
    # entity == self, parent == node
    return '' unless node && entity

    membership = if entity.is_a?(Group) && node.is_a?(Person)
                   Membership.find_by(group: entity, member: node)
                 elsif entity.is_a?(Person) && node.is_a?(Group)
                   Membership.find_by(group: node, member: entity)
                 end

    position = membership&.last_position
    return '' unless position&.title

    if position.end_date.present? && position.start_date.present?
      if position.end_date == position.start_date
        "#{position.title} | (#{position.formatted_start_date})"
      else
        "#{position.title} | (#{position.formatted_start_date} - #{position.formatted_end_date})"
      end
    elsif position.start_date.present?
      "#{position.title} | (since #{position.formatted_start_date})"
    elsif position.end_date.present?
      "#{position.title} | (until #{position.formatted_end_date})"
    end
  end
end
