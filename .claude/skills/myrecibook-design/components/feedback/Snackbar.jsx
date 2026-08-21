import React from 'react';

/**
 * Floating snackbar — inverse surface, radius 12, elev-2.
 * Calm receipts: "Notes saved", "Added to grocery — checked-off
 * items skipped", "Screenshot saved for your next import".
 */
export function Snackbar({ message, action, onAction, style = {} }) {
  return (
    <div
      style={{
        position: 'absolute',
        left: 20,
        right: 20,
        bottom: 20,
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        padding: '13px 16px',
        background: 'var(--inverse-surface)',
        color: 'var(--inverse-on-surface)',
        borderRadius: 'var(--radius-md)',
        boxShadow: 'var(--elev-2)',
        fontFamily: 'var(--font-body)',
        fontSize: 'var(--body-lg-size)',
        lineHeight: 1.4,
        zIndex: 40,
        ...style,
      }}
    >
      <span style={{ flex: 1 }}>{message}</span>
      {action && (
        <button
          onClick={onAction}
          style={{
            border: 'none',
            background: 'transparent',
            color: 'var(--inverse-primary)',
            fontFamily: 'var(--font-body)',
            fontSize: 13,
            fontWeight: 'var(--weight-semibold)',
            cursor: 'pointer',
            padding: 0,
          }}
        >
          {action}
        </button>
      )}
    </div>
  );
}
