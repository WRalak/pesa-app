import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: { '/admin/v1': { target: process.env.VITE_API_PROXY ?? 'http://localhost:4000', changeOrigin: true } },
  },
  build: { sourcemap: false, target: 'es2022' },
  test: { environment: 'jsdom', setupFiles: ['./src/test-setup.ts'], globals: true },
} as never);
