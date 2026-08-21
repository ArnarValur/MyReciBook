import React from 'react';
import { Icon } from '../icon/Icon.jsx';

/**
 * Editor duration pill: schedule icon, a number field, min/hr toggle —
 * "min" is a control, never typed. Reports total minutes (null when
 * empty/unparseable). Comma decimals accepted ("1,5" hr → 90).
 */
export function DurationField({ initialMinutes = null, onChanged, hint = '25', style = {} }) {
  const whole = initialMinutes != null && initialMinutes >= 60 && initialMinutes % 60 === 0;
  const [unit, setUnit] = React.useState(whole ? 'hr' : 'min');
  const [text, setText] = React.useState(initialMinutes == null ? '' : String(whole ? initialMinutes / 60 : initialMinutes));
  const total = (t, u) => {
    const v = parseFloat(t.trim().replace(',', '.'));
    if (isNaN(v) || v <= 0) return null;
    const m = Math.round(u === 'hr' ? v * 60 : v);
    return m < 1 ? null : m;
  };
  const emit = (t, u) => onChanged && onChanged(total(t, u));
  const chip = (u) => (
    <button
      onClick={() => { setUnit(u); emit(text, u); }}
      style={{
        padding: '6px 9px',
        border: 'none',
        borderRadius: 'var(--radius-full)',
        background: unit === u ? 'var(--secondary-container)' : 'transparent',
        color: unit === u ? 'var(--on-secondary-container)' : 'var(--on-surface-variant)',
        fontFamily: 'var(--font-body)',
        fontSize: 'var(--label-sm-size)',
        fontWeight: 'var(--weight-semibold)',
        letterSpacing: '0.2px',
        cursor: 'pointer',
        flex: 'none',
      }}
    >
      {u}
    </button>
  );
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 4, height: 40, padding: '0 5px 0 13px', border: '1px solid var(--hairline)', borderRadius: 'var(--radius-full)', boxSizing: 'border-box', ...style }}>
      <Icon name="schedule" size={16} color="var(--primary)" />
      <input
        type="text"
        inputMode="decimal"
        value={text}
        placeholder={hint}
        onChange={(e) => { const t = e.target.value.replace(/[^0-9.,]/g, ''); setText(t); emit(t, unit); }}
        style={{ flex: 1, minWidth: 0, border: 'none', outline: 'none', background: 'transparent', fontFamily: 'var(--font-body)', fontSize: 'var(--label-md-size)', fontWeight: 'var(--weight-medium)', color: 'var(--on-surface)' }}
      />
      {chip('min')}
      {chip('hr')}
    </div>
  );
}
