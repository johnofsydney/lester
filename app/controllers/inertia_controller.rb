class InertiaController < ApplicationController

  layout -> { 'widescreen' }

  # TODO: Where are affiliated groups???
  # TODO: Transfers need to be added to the network graph

  def network_graph_person
    @action = 'network_graph_person'
    @person = Person.find(params[:id])
    @depth = define_depth
    @toast_note = define_toast_note
    session[:depth] = @depth
    @nodes = @person.consolidated_descendents(depth: @depth)
    @active_nodes = @nodes.map { |node| configure_node(node) }
    @edges = define_edges

    render inertia: 'NetworkGraph', props: {
      name: @person.name,
      json_nodes: @active_nodes.to_json,
      json_edges: @edges.to_json
    }
  end

  def network_graph_group
    @action = 'network_graph_group'
    @group = Group.find(params[:id])
    @depth = define_depth
    @toast_note = define_toast_note
    session[:depth] = @depth
    @nodes = @group.consolidated_descendents(depth: @depth)
    @edges = define_edges

    render inertia: 'NetworkGraph', props: {
      name: @group.name,
      json_nodes: @nodes.map { |node| configure_node(node) }.to_json,
      json_edges: @edges.to_json
    }
  end

  def ids_people_descendents
    @nodes.filter{|n| n.klass == 'Person' }
          .map{|n| n.id }
  end

  def ids_group_descendents
    @nodes.filter{|n| n.klass == 'Group' }
          .map{|n| n.id }
  end

  def define_edges
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
      size: node.size,
      url: node.url
    }
  end

  def define_toast_note
    return "Using your setting of depth: #{params[:depth]}. Increase the depth of the network to show more nodes." if depth_in_params?
    return "Using stored setting of depth: #{session[:depth]}. Increase the depth of the network to show more nodes." if depth_in_session?

    "Using default setting of depth: 2. Increase the depth of the network to show more nodes. Larger value will take longer to calculate."
  end
  def define_depth
    return params[:depth].to_i if depth_in_params?
    return session[:depth].to_i if depth_in_session?

    2
  end

  def depth_in_params?
    params[:depth].present? && params[:depth].to_i > 0
  end

  def depth_in_session?
    session[:depth].present? && session[:depth].to_i > 0
  end
end
