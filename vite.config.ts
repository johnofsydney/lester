import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import inject from "@rollup/plugin-inject";

export default defineConfig({
  define: {
    global: 'window', // Had to add this manually
  },
  plugins: [
    inject({   // => that should be first under plugins array
      $: 'jquery',
      jQuery: 'jquery',
      }),
    react(),
    RubyPlugin()
  ],
  resolve: {
    alias: {
    },
  },
})
