import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  define: {
    global: 'window', // Had to add this manually
  },
  plugins: [
    react(),
    RubyPlugin()
  ],
  resolve: {
    alias: {
      jquery: 'jquery/src/jquery',
    },
  },
})
