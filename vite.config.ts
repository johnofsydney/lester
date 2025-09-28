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
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'], // adjust based on your dependencies
        },
      },
    },
  },
  // Production optimizations
  esbuild: {
    drop: process.env.NODE_ENV === 'production' ? ['console', 'debugger'] : [],
  },
})
