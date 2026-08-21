import React from 'react';
import { Icon } from '../icon/Icon.jsx';

/**
 * Diagonal-striped placeholder — stands in wherever a user
 * screenshot would render but none exists. Never ship real
 * artwork in these slots; the stripes ARE the design.
 */
export function StripedPlaceholder({ icon, height = '100%', style = {} }) {
  return (
    <div
      className="rb-stripes"
      style={{
        width: '100%',
        height,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        ...style,
      }}
    >
      {icon && <Icon name={icon} size={30} color="var(--on-surface-variant)" />}
    </div>
  );
}
