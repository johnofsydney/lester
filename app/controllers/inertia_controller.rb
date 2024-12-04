class InertiaController < ApplicationController

  layout -> { 'widescreen' }
  def network_graph
    @person = Person.find(params[:id])
    @nodes = @person.consolidated_descendents(depth: 2)

    render inertia: 'PersonNetworkGraph', props: {
      name: @person.name,
      active_nodes: active_nodes.to_json,
      person_edges: person_edges.to_json
    }
  end

  def active_nodes
    person_nodes # + person
  end

  def person_nodes
    @nodes.map { |node| configure_node(node) }
  end

  def ids_people_descendents
    @nodes.filter{|n| n.klass == 'Person' }
          .map{|n| n.id }
  end

  def ids_group_descendents
    @nodes.filter{|n| n.klass == 'Group' }
          .map{|n| n.id }
  end

  def person_edges
    all_memberships_of_descendents.map { |membership| configure_edge(membership) }
  end

  def all_memberships_of_descendents
    Membership.where(member_id: ids_people_descendents, member_type: 'Person')
              .or(Membership.where(member_id: ids_group_descendents, member_type: 'Group'))
              .or(Membership.where(group_id: ids_group_descendents))
  end

  def configure_edge(membership)
    member_id = "#{membership.member_type.downcase}_#{membership.member_id}"
    group_id = "group_#{membership.group_id}"
    {
      from: group_id,
      to: member_id
    }
  end

  def configure_node(node)
    id = "#{node.klass.downcase}_#{node.id}"

    {
      id: id,
      label: node.name,
      depth: node.depth,
      shape: node.shape,
      color: node.color,
      mass: node.mass,
      size: node.size
    }
  end
end
