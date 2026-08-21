import React from 'react';
import { Icon } from '../icon/Icon.jsx';

/**
 * The 52px gradient FAB — the import door. 135° primary-container
 * → primary, white add glyph, strong Moody Blue glow.
 */
export function GradientFab({ icon = 'add', onClick, style = {} }) {
  return (
    <button
      onClick={onClick}
      style={{
        width: 'var(--fab-size)',
        height: 'var(--fab-size)',
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        borderRadius: '50%',
        border: 'none',
        background: 'var(--gradient-fab)',
        boxShadow: 'var(--glow-fab)',
        cursor: 'pointer',
        padding: 0,
        flex: 'none',
        transition: 'transform var(--dur-fast) var(--ease-standard)',
        ...style,
      }}
      onMouseDown={(e) => { e.currentTarget.style.transform = 'scale(0.95)'; }}
      onMouseUp={(e) => { e.currentTarget.style.transform = ''; }}
      onMouseLeave={(e) => { e.currentTarget.style.transform = ''; }}
    >
      <Icon name={icon} size={24} color="var(--on-primary)" />
    </button>
  );
}
