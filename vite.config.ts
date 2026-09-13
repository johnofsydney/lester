import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import inject from "@rollup/plugin-inject";

export default defineConfig({
  define: {
    global: 'window', // Had to add this manually
  },
  plugins: [
    react(),
    RubyPlugin()
  ],
  build: {
    outDir: 'public/vite',
    chunkSizeWarningLimit: 1000, // Adjust warning limit if needed
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes('node_modules/react') || id.includes('node_modules/react-dom')) {
            return 'vendor'
          }
          if (id.includes('node_modules/@inertiajs/react')) {
            return 'inertia'
          }
        },
      },
    },
  },
  // Production optimizations
  esbuild: {
    drop: process.env.NODE_ENV === 'production' ? ['console', 'debugger'] : [],
  },
})
