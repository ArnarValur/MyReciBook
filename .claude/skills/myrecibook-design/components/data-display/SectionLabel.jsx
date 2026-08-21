import React from 'react';

/**
 * Tiny tracked uppercase section label — `INGREDIENTS · 8`.
 * 11px w600, +0.9px tracking, on-surface-variant.
 */
export function SectionLabel({ children, trailing, style = {} }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6, ...style }}>
      <span
        style={{
          fontFamily: 'var(--font-body)',
          fontSize: 'var(--label-sm-size)',
          fontWeight: 'var(--weight-semibold)',
          letterSpacing: 'var(--label-sm-tracking)',
          textTransform: 'uppercase',
          color: 'var(--on-surface-variant)',
        }}
      >
        {children}
      </span>
      {trailing}
    </div>
  );
}
