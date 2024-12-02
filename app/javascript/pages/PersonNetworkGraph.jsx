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
    const color = node.label === name ? 'rgba(240,110,110' : 'rgba(220,220,115'
            return (
              {
                id: node.id,
                label: node.label,
                // value: node.value,
                color: color
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
      // shape: 'dot',
      // size: 30,
      font: {
        size: 12,
        color: '#000000',
      },
      borderWidth: 2,
      chosen: true,
      shape: 'box',
      margin: 10,
      opacity: 0.5,
    },
    edges: {
      width: 2,
      color: {inherit: 'from'},
    },
  }

  return (
    <>
      <div id="network">
        <h1>Hello {name}!</h1>
        <h2>Not playin nice with Phlex Layout</h2>
        <p>Try moving the entire People Layout to erb, and see if can drop this JSX rendering into a partial??</p>
        {/* <p>{active_nodes}</p>
        <p>{person_edges}</p> */}


        {/* <div>
          {JSON.parse(active_nodes).map((node, index) => {
            return (
              <div>
                <p>{node.id}</p>
                <p>{node.label}</p>
              </div>
            )
          })}
        </div> */}

        <Graph
          graph={graph}
          options={options}
          style={{ height: '90vh' }}
        />
      </div>
    </>
  )
}