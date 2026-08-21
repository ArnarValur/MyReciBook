import React from 'react';

const HEIGHTS = { md: 'var(--button-h)', sm: 'var(--button-sm-h)' };

/**
 * Stadium button — every MyReciBook button is a pill (StadiumBorder).
 * Variants map 1:1 to the Flutter theme: filled / tonal / outlined /
 * text / danger (the destructive-confirm verb).
 */
export function Button({ variant = 'filled', size = 'md', icon, trailingIcon, fullWidth = false, disabled = false, children, style = {}, ...rest }) {
  const base = {
    display: fullWidth ? 'flex' : 'inline-flex',
    width: fullWidth ? '100%' : undefined,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    height: HEIGHTS[size] || HEIGHTS.md,
    padding: size === 'sm' ? '0 14px' : '0 24px',
    borderRadius: 'var(--radius-full)',
    border: 'none',
    fontFamily: 'var(--font-body)',
    fontSize: size === 'sm' ? 13 : 'var(--label-lg-size)',
    fontWeight: 'var(--weight-semibold)',
    cursor: disabled ? 'default' : 'pointer',
    opacity: disabled ? 0.45 : 1,
    transition: 'filter var(--dur-fast) var(--ease-standard), transform var(--dur-fast) var(--ease-standard)',
    userSelect: 'none',
  };
  const variants = {
    filled: { background: 'var(--primary)', color: 'var(--on-primary)', boxShadow: 'var(--elev-1)' },
    tonal: { background: 'var(--secondary-container)', color: 'var(--on-secondary-container)' },
    outlined: { background: 'transparent', color: 'var(--primary)', border: 'var(--border-focus) solid var(--secondary)', height: size === 'sm' ? HEIGHTS.sm : 44 },
    text: { background: 'transparent', color: 'var(--primary)', fontSize: 13, padding: '0 12px', height: size === 'sm' ? HEIGHTS.sm : 40 },
    danger: { background: 'var(--error)', color: 'var(--on-error)' },
  };
  return (
    <button
      disabled={disabled}
      style={{ ...base, ...(variants[variant] || variants.filled), ...style }}
      onMouseEnter={(e) => { if (!disabled) e.currentTarget.style.filter = 'brightness(1.08)'; }}
      onMouseLeave={(e) => { e.currentTarget.style.filter = ''; e.currentTarget.style.transform = ''; }}
      onMouseDown={(e) => { if (!disabled) e.currentTarget.style.transform = 'scale(0.98)'; }}
      onMouseUp={(e) => { e.currentTarget.style.transform = ''; }}
      {...rest}
    >
      {icon}
      {children}
      {trailingIcon}
    </button>
  );
}
