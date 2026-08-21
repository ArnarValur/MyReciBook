import React from 'react';
import { Icon } from '../icon/Icon.jsx';
import { MetaChip } from './MetaChip.jsx';

/**
 * The ONE pantry product card — used by the Pantry list and the diary's
 * Add-food picker; change it here, both follow. 38px photo thumb
 * (secondary-container kitchen tile when absent), name + brand·quantity
 * meta, optional kcal MetaChip.
 */
export function ProductRow({ name, brand, quantity, kcal, image, onClick, style = {} }) {
  const meta = [brand, quantity].filter(Boolean).join(' · ');
  return (
    <div
      onClick={onClick}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        background: 'var(--surface-container-lowest)',
        border: '1px solid var(--hairline)',
        borderRadius: 14,
        boxShadow: 'var(--elev-1)',
        padding: '10px 14px',
        cursor: onClick ? 'pointer' : 'default',
        ...style,
      }}
    >
      {image ? (
        <img src={image} alt="" style={{ width: 38, height: 38, borderRadius: 12, objectFit: 'cover', flex: 'none' }} />
      ) : (
        <span style={{ width: 38, height: 38, borderRadius: 12, background: 'var(--secondary-container)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flex: 'none' }}>
          <Icon name="kitchen" size={20} color="var(--on-secondary-container)" />
        </span>
      )}
      <span style={{ flex: 1, minWidth: 0 }}>
        <span style={{ display: 'block', fontFamily: 'var(--font-body)', fontSize: 'var(--body-lg-size)', fontWeight: 'var(--weight-semibold)', color: 'var(--on-surface)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{name}</span>
        {meta && <span style={{ display: 'block', fontFamily: 'var(--font-body)', fontSize: 'var(--body-sm-size)', color: 'var(--on-surface-variant)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{meta}</span>}
      </span>
      {kcal != null && <MetaChip label={`${Math.round(kcal)} kcal`} />}
    </div>
  );
}
