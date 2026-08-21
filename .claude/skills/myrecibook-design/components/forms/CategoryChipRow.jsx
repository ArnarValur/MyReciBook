import React from 'react';

/**
 * The category chip row — pantry shelf + Add-food drawer share it.
 * DIFFERENT from FilterChip: selected = solid PRIMARY fill. Labels
 * carry counts ("🥦 Produce 12"); emoji render as text here (the one
 * emoji surface in the app). null active = "All".
 */
export function CategoryChipRow({ categories = [], active = null, onSelect, allLabel = 'All', style = {} }) {
  const pill = (key, label, selected) => (
    <button
      key={key === null ? '__all' : key}
      onClick={onSelect ? () => onSelect(key) : undefined}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        padding: '8px 14px',
        border: 'none',
        borderRadius: 'var(--radius-full)',
        background: selected ? 'var(--primary)' : 'var(--surface-container-high)',
        color: selected ? 'var(--on-primary)' : 'var(--on-surface)',
        fontFamily: 'var(--font-body)',
        fontSize: 'var(--label-md-size)',
        fontWeight: 'var(--weight-medium)',
        whiteSpace: 'nowrap',
        cursor: 'pointer',
        flex: 'none',
        transition: 'background var(--dur-fast) var(--ease-standard)',
      }}
    >
      {label}
    </button>
  );
  return (
    <div style={{ display: 'flex', gap: 8, overflowX: 'auto', ...style }}>
      {pill(null, allLabel, active === null)}
      {categories.map((c) => pill(c.key, c.count != null ? `${c.label} ${c.count}` : c.label, active === c.key))}
    </div>
  );
}
