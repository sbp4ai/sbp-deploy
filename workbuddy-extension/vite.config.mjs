import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { federation } from '@module-federation/vite';

// Work Buddy consumes this as a Module-Federation remote. The host loads
// ./ui/assets/remoteEntry.js (declared in extension.json) and mounts ./Main
// inside the SBP4AI sidebar entry. ./Main simply embeds the LOCAL panel
// (http://127.0.0.1:20016/static/qwapp.html), which drives the local tmux
// agent sessions — same design as the Qwen Work qwapp.
const PANEL_URL = process.env.SBP_PANEL_URL || 'http://127.0.0.1:20016/static/qwapp.html';

export default defineConfig({
  plugins: [
    react(),
    federation({
      name: 'sbp4ai',
      filename: 'remoteEntry.js',
      exposes: {
        './Main': './src/Main.jsx',
      },
      shared: {
        react: { singleton: true, requiredVersion: '^18.3.1' },
        'react-dom': { singleton: true, requiredVersion: '^18.3.1' },
      },
    }),
  ],
  define: {
    __SBP_PANEL_URL__: JSON.stringify(PANEL_URL),
  },
  build: {
    outDir: 'ui/assets',
    emptyOutDir: true,
  },
});
