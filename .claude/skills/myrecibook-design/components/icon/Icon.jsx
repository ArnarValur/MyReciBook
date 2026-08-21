import React from 'react';

/**
 * Material Symbols Rounded glyph — the app's ONLY icon system
 * (Flutter `Icons.*_rounded`). `fill` for active/selected states.
 */
export function Icon({ name, size = 24, weight = 400, fill = false, color = 'currentColor', style = {}, ...rest }) {
  return (
    <span
      className="material-symbols-rounded"
      style={{
        fontSize: size,
        lineHeight: 1,
        color,
        fontVariationSettings: `'FILL' ${fill ? 1 : 0}, 'wght' ${weight}, 'GRAD' 0, 'opsz' ${Math.min(48, Math.max(20, size))}`,
        userSelect: 'none',
        flex: 'none',
        ...style,
      }}
      {...rest}
    >
      {name}
    </span>
  );
}
