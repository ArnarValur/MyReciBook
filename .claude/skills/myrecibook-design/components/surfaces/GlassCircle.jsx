import React from 'react';
import { Icon } from '../icon/Icon.jsx';

/**
 * 40px frosted-glass circular button — hero overlays (back,
 * edit, favorite, delete over the recipe cover).
 */
export function GlassCircle({ icon, fill = false, iconColor, onClick, style = {} }) {
  return (
    <button
      onClick={onClick}
      style={{
        width: 'var(--glass-circle)',
        height: 'var(--glass-circle)',
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        borderRadius: '50%',
        background: 'var(--glass-fill)',
        border: '1px solid var(--glass-border)',
        backdropFilter: 'blur(var(--blur-glass-soft))',
        WebkitBackdropFilter: 'blur(var(--blur-glass-soft))',
        cursor: 'pointer',
        padding: 0,
        flex: 'none',
        ...style,
      }}
    >
      <Icon name={icon} size={20} fill={fill} color={iconColor || 'var(--on-surface)'} />
    </button>
  );
}
