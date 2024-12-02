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
    person_nodes + person
  end

  def person_nodes
    @person.nodes.map { |node| {id: node.id, label: node.name} }
  end

  def person
    [{id: -@person.id, label: @person.name}]
  end

  def person_edges
    @person.nodes.map { |node| {from: -@person.id, to: node.id} }
  end
end