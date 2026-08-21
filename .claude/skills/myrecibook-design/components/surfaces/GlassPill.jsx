import React from 'react';
import { Icon } from '../icon/Icon.jsx';

/**
 * Frosted-glass stadium pill with icon + tiny label — the
 * cover ⇄ original provenance flipper on the recipe hero.
 */
export function GlassPill({ icon, label, onClick, style = {} }) {
  return (
    <button
      onClick={onClick}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 5,
        padding: '6px 12px',
        borderRadius: 'var(--radius-full)',
        background: 'var(--glass-fill)',
        border: '1px solid var(--glass-border)',
        backdropFilter: 'blur(var(--blur-glass-soft))',
        WebkitBackdropFilter: 'blur(var(--blur-glass-soft))',
        fontFamily: 'var(--font-body)',
        fontSize: 11.5,
        fontWeight: 'var(--weight-semibold)',
        letterSpacing: '0.2px',
        color: 'var(--on-surface)',
        cursor: 'pointer',
        ...style,
      }}
    >
      <Icon name={icon} size={15} />
      {label}
    </button>
  );
}
