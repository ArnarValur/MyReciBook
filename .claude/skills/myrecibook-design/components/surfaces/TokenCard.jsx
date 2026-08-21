import React from 'react';

/**
 * The house card: surface-container-lowest, hairline border,
 * radius 12–16, soft blue-tinted shadow. `selected` switches to
 * the 1.5px primary border + Moody Blue glow (selected storage
 * option, merge prompt, paywall price card).
 */
export function TokenCard({ children, padding = 12, radius = 12, selected = false, shadow = true, color, borderColor, style = {}, ...rest }) {
  return (
    <div
      style={{
        background: color || 'var(--surface-container-lowest)',
        borderRadius: radius,
        border: selected
          ? 'var(--border-focus) solid var(--primary)'
          : `var(--border-hairline) solid ${borderColor || 'var(--hairline)'}`,
        boxShadow: selected ? 'var(--glow-primary)' : shadow ? 'var(--elev-1)' : 'none',
        padding,
        ...style,
      }}
      {...rest}
    >
      {children}
    </div>
  );
}
