import React from 'react';
import { Icon } from '../icon/Icon.jsx';
import { GlassPill } from '../surfaces/GlassPill.jsx';

/**
 * Tappable cover slot for the editors: the chosen photo (with a "change"
 * glass pill), or an "Add a cover photo" affordance. Camera/gallery
 * choice happens in a sheet the screen owns — this is just the door.
 */
export function CoverPickerField({ src = null, height = 140, onClick, style = {} }) {
  if (!src) {
    return (
      <div
        onClick={onClick}
        role="button"
        style={{
          height,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 6,
          background: 'var(--surface-container-low)',
          border: '1px solid var(--hairline)',
          borderRadius: 'var(--radius-md)',
          cursor: 'pointer',
          ...style,
        }}
      >
        <Icon name="add_a_photo" size={22} color="var(--primary)" />
        <span style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--label-lg-size)', fontWeight: 'var(--weight-semibold)', color: 'var(--primary)' }}>Add a cover photo</span>
      </div>
    );
  }
  return (
    <div onClick={onClick} role="button" style={{ position: 'relative', height, borderRadius: 'var(--radius-md)', overflow: 'hidden', cursor: 'pointer', ...style }}>
      <img src={src} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
      <div style={{ position: 'absolute', right: 8, bottom: 8, pointerEvents: 'none' }}>
        <GlassPill icon="edit" label="change" />
      </div>
    </div>
  );
}
