import React from 'react';
import { Icon } from '../icon/Icon.jsx';

/**
 * The one back button — arrow_back (rounded), 22px app-bar icon size,
 * 44px hit target, tooltip "Back". Flutter's BackButton forces the
 * platform glyph; this stays ours.
 */
export function AppBackButton({ onClick, color = 'var(--on-surface)', style = {} }) {
  return (
    <button
      onClick={onClick}
      title="Back"
      style={{ width: 44, height: 44, border: 'none', background: 'transparent', borderRadius: '50%', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', padding: 0, flex: 'none', ...style }}
    >
      <Icon name="arrow_back" size={22} color={color} />
    </button>
  );
}
