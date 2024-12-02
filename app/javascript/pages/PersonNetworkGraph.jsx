// import { Head } from '@inertiajs/react'
import React from 'react'
import { useState } from 'react'
import Graph from 'react-vis-network-graph'

// import inertiaSvg from '/assets/inertia.svg'
// import reactSvg from '/assets/react.svg'
// import viteRubySvg from '/assets/vite_ruby.svg'

import cs from './InertiaExample.module.css'

export default function PersonNetworkGraph({ name, active_nodes, person_edges }) {

  const parsed_nodes = JSON.parse(active_nodes).map((node) => {
            return (
              { id: node.id, label: node.label }
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
  const options = {}

  return (
    <>
      <div id="network">
        <h1>Hello {name}!</h1>
        <h2>Not playin nice with Phlex Layout</h2>
        <p>Try moving the entire People Layout to erb, and see if can drop this JSX rendering into a partial??</p>
        <p>{active_nodes}</p>
        <p>{person_edges}</p>


        <div>
          {JSON.parse(active_nodes).map((node, index) => {
            return (
              <div>
                <p>{node.id}</p>
                <p>{node.label}</p>
              </div>
            )
          })}
        </div>

        <Graph
          graph={graph}
          options={options}
          style={{ height: '640px' }}
        />
      </div>
    </>
  )
}