import React from 'react';
import { Icon } from '../icon/Icon.jsx';

/** "400 g spaghetti" → bold leading quantity, regular rest. */
export function qtyBold(raw) {
  const m = raw.match(/^[\d½¼¾⅓⅔][\d\s./,½¼¾⅓⅔×x–-]*\s*(?:[a-zA-Zæøåðþ]+\.?)?/);
  if (!m || m[0].length === 0 || m[0].length >= raw.length) return raw;
  return (
    <>
      <strong style={{ fontWeight: 'var(--weight-bold)' }}>{raw.slice(0, m[0].length)}</strong>
      {raw.slice(m[0].length)}
    </>
  );
}

/**
 * Check-off row for ingredients & grocery items: 18px radius-6
 * checkbox, bold leading quantity, strikethrough when checked.
 * Kitchen-session state — the caller owns it.
 */
export function IngredientRow({ text, checked = false, onToggle, trailing, staple = false, last = false, style = {} }) {
  const row = (
    <div
      onClick={onToggle}
      style={{
        display: 'flex',
        alignItems: 'flex-start',
        gap: 10,
        padding: '9px 0',
        borderBottom: last ? 'none' : '1px solid var(--separator)',
        cursor: onToggle ? 'pointer' : 'default',
        opacity: staple ? 0.55 : 1,
        ...style,
      }}
    >
      <span
        style={{
          width: 'var(--checkbox-size)',
          height: 'var(--checkbox-size)',
          marginTop: 1,
          flex: 'none',
          display: 'inline-flex',
          alignItems: 'center',
          justifyContent: 'center',
          borderRadius: 6,
          background: checked ? 'var(--primary)' : 'transparent',
          border: checked ? 'none' : '2px solid var(--outline)',
          transition: 'background var(--dur-fast) var(--ease-standard)',
        }}
      >
        {checked && <Icon name="check" size={13} color="var(--on-primary)" />}
      </span>
      <span
        style={{
          flex: 1,
          fontFamily: 'var(--font-body)',
          fontSize: 'var(--body-md-size)',
          lineHeight: 1.45,
          textDecoration: checked ? 'line-through' : 'none',
          color: checked ? 'var(--on-surface-variant)' : 'var(--on-surface)',
        }}
      >
        {qtyBold(text)}
      </span>
      {trailing && (
        <span style={{ fontFamily: 'var(--font-body)', fontSize: 11, color: 'var(--on-surface-variant)', alignSelf: 'center' }}>
          {trailing}
        </span>
      )}
      {staple && (
        <span
          style={{
            alignSelf: 'center',
            padding: '2px 8px',
            borderRadius: 8,
            background: 'var(--surface-container-high)',
            fontFamily: 'var(--font-body)',
            fontSize: 10.5,
            fontWeight: 'var(--weight-semibold)',
            color: 'var(--on-surface-variant)',
          }}
        >
          staple
        </span>
      )}
    </div>
  );
  return row;
}
