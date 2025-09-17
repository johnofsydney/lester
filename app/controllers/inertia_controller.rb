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
    # session[:depth] = depth

    if @person.cache_fresh?
      render inertia: 'NetworkGraph', props: {
        url: "/people/#{person.id}",
        name: person.name,
        json_nodes: nodes.map { |node| configure_node(node) }.to_json,
        json_edges: edges.to_json
      }
    else
      BuildPersonCachedDataJob.perform_async(@person.id)

      render plain: "Building cached data. Please refresh in a moment.", status: 200
    end
  end

  def network_graph_group
    @group = Group.find(params[:id])

    reduce_network_depth if network_too_big?

    @action = 'network_graph_group'
    @toast_note ||= define_toast_note
    session[:depth] = depth

    if @group.cache_fresh?
      render inertia: 'NetworkGraph', props: {
        url: "/groups/#{group.id}",
        name: group.name,
        json_nodes: nodes.map { |node| configure_node(node) }.to_json,
        json_edges: edges.to_json
      }
    else
      BuildGroupCachedDataJob.perform_async(@group.id)

      render plain: "Building cached data. Please refresh in a moment.", status: 200
    end
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

    node.cached.consolidated_descendents
  end

  def all_memberships_of_descendents
    ActiveRecord::Base.logger.silence do
      # There is a good index for this, and it is ONE query, so it's not very slow
      Membership.where(member_id: ids_people_descendents, member_type: 'Person')
                .or(Membership.where(member_id: ids_group_descendents, member_type: 'Group'))
                .or(Membership.where(group_id: ids_group_descendents))
    end
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
      url: "#{node.url}/network_graph",
      klass: node.klass
    }
  end

  def define_toast_note
    'Building network graph... this may take a few seconds.'
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
