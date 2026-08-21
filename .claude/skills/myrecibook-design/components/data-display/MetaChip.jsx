import React from 'react';
import { Icon } from '../icon/Icon.jsx';

/**
 * Stadium meta chip on surface-container-high with a primary
 * icon — recipe time ("25 min") and servings ("Serves 4").
 */
export function MetaChip({ icon, label, onClick, style = {} }) {
  return (
    <span
      onClick={onClick}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 5,
        padding: '7px 13px',
        borderRadius: 'var(--radius-full)',
        background: 'var(--surface-container-high)',
        fontFamily: 'var(--font-body)',
        fontSize: 'var(--label-md-size)',
        fontWeight: 'var(--weight-medium)',
        color: 'var(--on-surface)',
        cursor: onClick ? 'pointer' : 'default',
        ...style,
      }}
    >
      {icon && <Icon name={icon} size={16} color="var(--primary)" />}
      {label}
    </span>
  );
}
