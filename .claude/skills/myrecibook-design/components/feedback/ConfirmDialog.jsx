import React from 'react';
import { Button } from '../forms/Button.jsx';

/**
 * THE canonical destructive confirm — reuse verbatim for any
 * destructive action; never draft new shapes. Title asks the
 * question, body states what survives before what stops,
 * actions are a safe text Cancel + a filled error verb.
 */
export function ConfirmDialog({ open = true, title, body, verb = 'Delete', onCancel, onConfirm, style = {} }) {
  if (!open) return null;
  return (
    <div
      style={{
        position: 'absolute',
        inset: 0,
        background: 'var(--scrim)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 28,
        zIndex: 50,
      }}
      onClick={onCancel}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          width: '100%',
          maxWidth: 320,
          background: 'var(--surface-container-lowest)',
          borderRadius: 'var(--radius-lg)',
          boxShadow: 'var(--elev-2)',
          padding: 24,
          ...style,
        }}
      >
        <div style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--title-lg-size)', fontWeight: 'var(--weight-bold)', color: 'var(--on-surface)' }}>
          {title}
        </div>
        <div style={{ marginTop: 10, fontFamily: 'var(--font-body)', fontSize: 'var(--body-lg-size)', lineHeight: 1.5, color: 'var(--on-surface-variant)' }}>
          {body}
        </div>
        <div style={{ marginTop: 18, display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
          <Button variant="text" onClick={onCancel}>Cancel</Button>
          <Button variant="danger" onClick={onConfirm}>{verb}</Button>
        </div>
      </div>
    </div>
  );
}
