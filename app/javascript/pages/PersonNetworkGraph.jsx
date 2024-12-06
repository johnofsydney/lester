// import { Head } from '@inertiajs/react'
import React from 'react'
import { useState } from 'react'
import Graph from 'react-vis-network-graph'

// import inertiaSvg from '/assets/inertia.svg'
// import reactSvg from '/assets/react.svg'
// import viteRubySvg from '/assets/vite_ruby.svg'

import cs from './InertiaExample.module.css'
import { shape } from 'prop-types'

export default function PersonNetworkGraph({ name, active_nodes, person_edges }) {
  const parsed_nodes = JSON.parse(active_nodes).map((node) => {
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

  const parsed_edges = JSON.parse(person_edges).map((edge) => {
    return (
      { from: edge.from, to: edge.to }
    )
  })

  const graph = {
    nodes: parsed_nodes,
    edges: parsed_edges,
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
      <div id="network">
        <h3 class="center">Network Diagram centred on {name}</h3>

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