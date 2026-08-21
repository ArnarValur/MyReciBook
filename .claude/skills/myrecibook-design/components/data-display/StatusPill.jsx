import React from 'react';
import { Icon } from '../icon/Icon.jsx';

/**
 * Quiet status pill — the "On this phone" / "Synced" storage
 * badge. Success-tinted fill, muted text; never shouts.
 */
export function StatusPill({ icon, label, style = {} }) {
  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 4,
        padding: '4px 10px',
        borderRadius: 'var(--radius-full)',
        background: 'var(--pill-success-tint)',
        fontFamily: 'var(--font-body)',
        fontSize: 'var(--label-sm-size)',
        fontWeight: 'var(--weight-semibold)',
        letterSpacing: '0.2px',
        color: 'var(--on-surface-variant)',
        ...style,
      }}
    >
      {icon && <Icon name={icon} size={13} color="var(--on-surface-variant)" />}
      {label}
    </span>
  );
}
