import { defineConfig } from 'vite'
import react, { reactCompilerPreset } from '@vitejs/plugin-react'
import babel from '@rolldown/plugin-babel'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    babel({ presets: [reactCompilerPreset()] })
  ],
  server: {
  port: 5173,
  strictPort: true,
  host: "0.0.0.0",
  origin: "http://0.0.0.0:5173",
   allowedHosts: [
    'frontend.development.posts.com',
    'frontend.staging.posts.com',
    'posts.com']
 },
})
