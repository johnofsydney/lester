class InertiaController < ApplicationController
  attr_reader :nodes, :person, :group

  layout -> { 'widescreen' }

  # TODO: Where are affiliated groups???
  # TODO: Transfers need to be added to the network graph

  def network_graph_person
    @person = Person.find(params[:id])

    reduce_network_depth if network_too_big?

    @action = 'network_graph_person' # required in layout
    @toast_note ||= define_toast_note # required in layout
    session[:depth] = depth

    render inertia: 'NetworkGraph', props: {
      name: person.name,
      json_nodes: nodes.map { |node| configure_node(node) }.to_json,
      json_edges: edges.to_json
    }
  end

  def network_graph_group
    @group = Group.find(params[:id])

    reduce_network_depth if network_too_big?

    @action = 'network_graph_group'
    @toast_note ||= define_toast_note
    session[:depth] = depth

    render inertia: 'NetworkGraph', props: {
      name: group.name,
      json_nodes: nodes.map { |node| configure_node(node) }.to_json,
      json_edges: edges.to_json
    }
  end

  def ids_people_descendents
    nodes.filter{|n| n.klass == 'Person' }
         .map{|n| n.id }
  end

  def ids_group_descendents
    nodes.filter{|n| n.klass == 'Group' }
         .map{|n| n.id }
  end

  def edges
    all_memberships_of_descendents.map { |membership| configure_edge(membership) }
  end

  def nodes
    node = person || group

    node.consolidated_descendents_depth(depth)
  end

  def all_memberships_of_descendents
    # There is a good index for this, and it is ONE query, so it's not very slow
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
    # arg node is a descendent
    id = "#{node.klass.downcase}_#{node.id}"

    {
      id: id,
      label: node.name,
      depth: node.depth,
      shape: node.shape,
      color: node.color,
      mass: node.mass,
      size: node.size,
      url: node.url,
      klass: node.klass
    }
  end

  def define_toast_note
    if depth_in_params?
      "Using your setting of depth: #{params[:depth]}. Increase the depth of the network to show more nodes."
    elsif depth_in_session?
      "Using stored setting of depth: #{session[:depth]}. Increase the depth of the network to show more nodes."
    else
      'Using default setting of depth: 2. Increase the depth of the network to show more nodes. Larger value will take longer to calculate.'
    end
  end
  def depth
    @depth ||= if depth_in_params?
                 params[:depth].to_i
               elsif depth_in_session?
                 session[:depth].to_i
               else
                 2
               end
  end

  def depth_in_params?
    params[:depth].present? && params[:depth].to_i > 0
  end

  def depth_in_session?
    session[:depth].present? && session[:depth].to_i > 0
  end

  def network_too_big?
    nodes_count = (@group || @person).nodes_count

    (depth > 2) && ((nodes_count * depth) > 1000)
  end

  def reduce_network_depth
    @toast_note = 'The network graph is too large to display. Depth re-adjusted to 1.'
      @alert = 'The network graph is too large to display. Depth re-adjusted to 1.'
      @depth = 1
  end
end
