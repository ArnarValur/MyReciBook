import React from 'react';
import { Icon } from '../icon/Icon.jsx';

/**
 * Stadium pill with −/+ around "N servings" — the word is rendered,
 * never typed. 40px, hairline border, 32px round step targets.
 */
export function ServingsStepper({ value, onChange, min = 1, max = 99, style = {} }) {
  const label = value === 1 ? '1 serving' : `${value} servings`;
  const step = (d) => onChange && onChange(Math.min(max, Math.max(min, value + d)));
  const btn = (icon, dis, d, title) => (
    <button
      onClick={dis ? undefined : () => step(d)}
      title={title}
      style={{ width: 32, height: 32, border: 'none', background: 'transparent', borderRadius: '50%', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', cursor: dis ? 'default' : 'pointer', padding: 0, flex: 'none' }}
    >
      <Icon name={icon} size={18} color={dis ? 'color-mix(in srgb, var(--on-surface-variant) 40%, transparent)' : 'var(--primary)'} />
    </button>
  );
  return (
    <div style={{ display: 'flex', alignItems: 'center', height: 40, padding: '0 4px', border: '1px solid var(--hairline)', borderRadius: 'var(--radius-full)', boxSizing: 'border-box', ...style }}>
      {btn('remove', value <= min, -1, 'Fewer servings')}
      <span style={{ flex: 1, textAlign: 'center', fontFamily: 'var(--font-body)', fontSize: 'var(--label-md-size)', fontWeight: 'var(--weight-medium)', color: 'var(--on-surface)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{label}</span>
      {btn('add', value >= max, 1, 'More servings')}
    </div>
  );
}
