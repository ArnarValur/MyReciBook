import React from 'react';
import { RecipeCover } from './RecipeCover.jsx';

/**
 * Cookbook grid card (2-col): 106px cover — the picked photo, else the
 * title-derived gradient tile with the LogoMark watermark (RecipeCover)
 * — 2-line title, meta line "25 min · Serves 4".
 */
export function RecipeCard({ title, meta, cover, onClick, style = {} }) {
  return (
    <div
      onClick={onClick}
      style={{
        background: 'var(--surface-container-lowest)',
        borderRadius: 'var(--radius-md)',
        border: '1px solid var(--hairline)',
        boxShadow: 'var(--elev-1)',
        overflow: 'hidden',
        cursor: onClick ? 'pointer' : 'default',
        ...style,
      }}
    >
      <div style={{ height: 106, background: 'var(--surface-container-low)' }}>
        <RecipeCover src={cover} title={title} />
      </div>
      <div style={{ padding: '9px 11px 11px' }}>
        <div
          style={{
            fontFamily: 'var(--font-body)',
            fontSize: 'var(--title-sm-size)',
            fontWeight: 'var(--weight-semibold)',
            lineHeight: 1.3,
            color: 'var(--on-surface)',
            display: '-webkit-box',
            WebkitLineClamp: 2,
            WebkitBoxOrient: 'vertical',
            overflow: 'hidden',
          }}
        >
          {title}
        </div>
        {meta && (
          <div
            style={{
              marginTop: 3,
              fontFamily: 'var(--font-body)',
              fontSize: 11.5,
              color: 'var(--on-surface-variant)',
              whiteSpace: 'nowrap',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
            }}
          >
            {meta}
          </div>
        )}
      </div>
    </div>
  );
}
