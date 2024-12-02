class InertiaController < ApplicationController
  def network_graph
    @person = Person.find(params[:id])

    p "network_graph"

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
    @person.consolidated_descendents(depth: 2)
           .map { |node| configure_node(node) }
  end

  def ids_people_descendents
    @person.consolidated_descendents(depth: 2)
           .filter{|n| n.klass == 'Person' }
           .map{|n| n.id }
  end

  def ids_group_descendents
    @person.consolidated_descendents(depth: 2)
           .filter{|n| n.klass == 'Group' }
           .map{|n| n.id }
  end

  def person_edges
    # @person.nodes.map { |node| {from: -@person.id, to: node.id} }

    Membership.where(member_id: ids_people_descendents, member_type: 'Person')
              .or(Membership.where(member_id: ids_group_descendents, member_type: 'Group'))
              .or(Membership.where(group_id: ids_group_descendents))
              .map { |membership| configure_edge(membership) }
  end

  def configure_edge(membership)
    member_id = membership.member_type == "Person" ? -membership.member_id : membership.member_id
    {
      from: member_id,
      to: membership.group_id
    }
  end

  def configure_node(node)
    id = node.klass == "Person" ? -node.id : node.id

    {
      id: id,
      label: node.name,
    }
  end
end


# Membership.where(member_id: 875, member_type: 'Person').or(Membership.where(member_id: 228, member_type: 'Group')).or(Membership.where(group_id: 228))