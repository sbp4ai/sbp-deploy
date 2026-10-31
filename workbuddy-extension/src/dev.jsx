import React from 'react';
import { createRoot } from 'react-dom/client';
import Main from './Main.jsx';

// Dev-only bootstrap so `vite` / `vite build` has an HTML entry.
// The shippable artifact is ui/assets/remoteEntry.js (the Module-Federation
// remote), not this file.
createRoot(document.getElementById('root')).render(<Main />);
