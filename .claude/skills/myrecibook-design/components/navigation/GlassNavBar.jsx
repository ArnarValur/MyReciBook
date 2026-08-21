import React from 'react';
import { Icon } from '../icon/Icon.jsx';
import { LogoMark } from '../brand/LogoMark.jsx';
import { GradientFab } from './GradientFab.jsx';

/**
 * Floating glass pill nav bar: 56px pill inside a 64px hint (FAB
 * overhang), 16px above the bottom edge, 20px side margins.
 * 4 tabs split 2+2 around the center gradient FAB — Cookbook ·
 * Grocery · [FAB] · slot 3 (feature-flagged: Food / Pantry / Unlock /
 * Queue) · Settings. The Cookbook tab draws the LogoMark (book only)
 * so the tab and the app icon are one mark. Content scrolls under.
 */
export function GlassNavBar({ items, active = 0, onTab, onFab, style = {} }) {
  const tabs = items || [
    { icon: 'menu_book', label: 'Cookbook', logo: true },
    { icon: 'checklist', label: 'Grocery' },
    { icon: 'download', label: 'Queue' },
    { icon: 'settings', label: 'Settings' },
  ];
  const item = (t, i) => {
    const selected = i === active;
    const color = selected ? 'var(--primary)' : 'var(--on-surface-variant)';
    return (
      <button
        key={t.label}
        onClick={onTab ? () => onTab(i) : undefined}
        style={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 2,
          border: 'none',
          background: 'transparent',
          cursor: 'pointer',
          padding: 0,
          color,
        }}
      >
        <span style={{ position: 'relative', display: 'inline-flex' }}>
          {t.logo ? <LogoMark size={22} withSteam={false} color={color} /> : <Icon name={t.icon} size={22} fill={selected} />}
          {t.badge > 0 && (
            <span
              style={{
                position: 'absolute',
                top: -4,
                right: -8,
                minWidth: 15,
                height: 15,
                padding: '0 4px',
                borderRadius: 'var(--radius-full)',
                background: 'var(--primary)',
                color: 'var(--on-primary)',
                fontFamily: 'var(--font-body)',
                fontSize: 10,
                fontWeight: 'var(--weight-bold)',
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              {t.badge}
            </span>
          )}
        </span>
        <span style={{ fontFamily: 'var(--font-body)', fontSize: 10.5, fontWeight: 'var(--weight-semibold)', letterSpacing: '0.2px' }}>
          {t.label}
        </span>
      </button>
    );
  };
  return (
    <div style={{ position: 'absolute', left: 20, right: 20, bottom: 16, height: 64, ...style }}>
      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          bottom: 0,
          height: 'var(--nav-pill-h)',
          display: 'flex',
          alignItems: 'stretch',
          borderRadius: 'var(--radius-full)',
          background: 'var(--glass-fill)',
          border: '1px solid var(--glass-border)',
          backdropFilter: 'blur(var(--blur-glass))',
          WebkitBackdropFilter: 'blur(var(--blur-glass))',
        }}
      >
        {item(tabs[0], 0)}
        {item(tabs[1], 1)}
        <div style={{ width: 60, flex: 'none' }}></div>
        {item(tabs[2], 2)}
        {item(tabs[3], 3)}
      </div>
      <div style={{ position: 'absolute', top: 0, left: '50%', transform: 'translateX(-50%)' }}>
        <GradientFab onClick={onFab} />
      </div>
    </div>
  );
}
