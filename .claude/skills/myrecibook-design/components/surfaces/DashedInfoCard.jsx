import React from 'react';

/**
 * Dashed-border info card — the quiet product-promise framing:
 * "Not a recipe? We skip it and say so — no junk lands in your book."
 */
export function DashedInfoCard({ children, style = {} }) {
  return (
    <div
      style={{
        padding: '11px 13px',
        border: '1px dashed color-mix(in srgb, var(--outline) 60%, transparent)',
        borderRadius: 'var(--radius-md)',
        fontFamily: 'var(--font-body)',
        fontSize: 12.5,
        lineHeight: 1.5,
        color: 'var(--on-surface-variant)',
        ...style,
      }}
    >
      {children}
    </div>
  );
}
