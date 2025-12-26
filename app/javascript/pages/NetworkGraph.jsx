import React from 'react'
import Graph from 'react-vis-network-graph'
// https://visjs.github.io/vis-network/docs/network/
// https://visjs.github.io/vis-network/docs/network/nodes.html

export default function NetworkGraph({ url, name, json_nodes, json_edges }) {
  const nodes = JSON.parse(json_nodes).map((node) => {
    return (
      {
        id: node.id,
        label: node.label,
        color: node.color,
        shape: node.shape,
        mass: node.mass,
        size: node.size,
        url: node.url
      }
    )
  })

  const edges = JSON.parse(json_edges).map((edge) => {
    return (
      { from: edge.from, to: edge.to }
    )
  })

  const graph = {
    nodes: nodes,
    edges: edges,
  }

  const options = {
    interaction: {navigationButtons: true},
    nodes: {
      font: {
        size: 12,
        color: '#000000',
      },
      borderWidth: 2,
      chosen: true,
      shape: 'box',
      margin: 10,
    },
    edges: {
      color: { inherit: true },
      width: 0.5,
      smooth: {
        type: "continuous",
      },
    },
  }

  const events = {
    selectNode: function (event) {
      const { nodes } = event;
      if (nodes.length === 1) {
        const node = graph.nodes.find(n => n.id === nodes[0]);
        if (node && node.url) {
          window.open(node.url, '_blank');
        }
      }
    }
  }

  return (
    <>
      <div className="bottom-0 results" id="network">
        <h3 className="center">
          Network Diagram centred on{' '}
          <a
            href={url}
            target="_blank"
            rel="noopener noreferrer"
            style={{ textDecoration: 'none' }}
          >
            {name}
          </a>
        </h3>

        <Graph
          graph={graph}
          options={options}
          events={events}
          style={{ height: '90vh', width: '100%' }}
        />
      </div>
    </>
  )
}
