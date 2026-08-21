import React from 'react';
import { Icon } from '../icon/Icon.jsx';

/**
 * Stadium segmented control — one pill container (3px padding,
 * surface-container-high), the active segment is a
 * surface-container-lowest pill with the card shadow.
 * Used by the import sheet ("One recipe · 3 shots / 3 separate
 * recipes") and Settings theme picker (with check icon).
 */
export function SegmentedControl({ options, value, onChange, showCheck = false, style = {} }) {
  return (
    <div
      style={{
        display: 'flex',
        padding: 3,
        background: 'var(--surface-container-high)',
        borderRadius: 'var(--radius-full)',
        ...style,
      }}
    >
      {options.map((opt) => {
        const o = typeof opt === 'string' ? { value: opt, label: opt } : opt;
        const selected = o.value === value;
        return (
          <button
            key={o.value}
            onClick={onChange ? () => onChange(o.value) : undefined}
            style={{
              flex: 1,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 5,
              height: 'var(--segment-h)',
              border: selected && showCheck ? '1px solid var(--hairline)' : 'none',
              borderRadius: 'var(--radius-full)',
              background: selected ? 'var(--surface-container-lowest)' : 'transparent',
              boxShadow: selected ? 'var(--elev-1)' : 'none',
              color: selected ? (showCheck ? 'var(--on-surface)' : 'var(--primary)') : 'var(--on-surface-variant)',
              fontFamily: 'var(--font-body)',
              fontSize: 'var(--label-md-size)',
              fontWeight: selected ? 'var(--weight-semibold)' : 'var(--weight-medium)',
              cursor: 'pointer',
              transition: 'background var(--dur-fast) var(--ease-standard), box-shadow var(--dur-fast) var(--ease-standard)',
            }}
          >
            {selected && showCheck && <Icon name="check" size={15} />}
            {o.label}
          </button>
        );
      })}
    </div>
  );
}
