import React from 'react';

// SBP4AI Work Buddy extension entry.
// Mounted by Work Buddy's federation loader as the "./Main" module of the
// "sbp4ai" remote. It simply embeds the LOCAL SBP4AI panel (which reads the
// user's local tmux agent sessions) inside the Work Buddy sidebar.
const PANEL_URL = __SBP_PANEL_URL__;

export default function Main() {
  return (
    <div style={{ position: 'fixed', inset: 0, background: '#0d1117' }}>
      <iframe
        src={PANEL_URL}
        title="SBP4AI"
        style={{ display: 'block', width: '100%', height: '100%', border: 0 }}
        allow="clipboard-read; clipboard-write"
        referrerPolicy="no-referrer-when-downgrade"
      />
    </div>
  );
}
