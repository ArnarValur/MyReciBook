import React from 'react';
import { Icon } from '../icon/Icon.jsx';

/**
 * 36px stadium filter chip (All / Favorites / Quick / Sweet).
 * Selected = secondary-container fill; icon turns with it.
 */
export function FilterChip({ label, icon, selected = false, onClick, style = {} }) {
  return (
    <button
      onClick={onClick}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 5,
        height: 'var(--chip-h)',
        padding: '0 14px',
        border: 'none',
        borderRadius: 'var(--radius-full)',
        background: selected ? 'var(--secondary-container)' : 'var(--surface-container-high)',
        color: selected ? 'var(--on-secondary-container)' : 'var(--on-surface)',
        fontFamily: 'var(--font-body)',
        fontSize: 'var(--label-md-size)',
        fontWeight: 'var(--weight-semibold)',
        cursor: 'pointer',
        transition: 'background var(--dur-fast) var(--ease-standard)',
        ...style,
      }}
    >
      {icon && <Icon name={icon} size={15} color={selected ? 'var(--on-secondary-container)' : 'var(--primary)'} />}
      {label}
    </button>
  );
}
