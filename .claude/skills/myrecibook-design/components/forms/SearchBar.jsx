import React from 'react';
import { Icon } from '../icon/Icon.jsx';

/**
 * Pill search field — 48px stadium on surface-container
 * ("Search your cookbook…").
 */
export function SearchBar({ placeholder = 'Search your cookbook…', value, onChange, style = {}, ...rest }) {
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 8,
        height: 'var(--search-h)',
        padding: '0 16px',
        background: 'var(--surface-container)',
        borderRadius: 'var(--radius-full)',
        ...style,
      }}
    >
      <Icon name="search" size={20} color="var(--on-surface-variant)" />
      <input
        type="text"
        value={value}
        onChange={onChange ? (e) => onChange(e.target.value) : undefined}
        placeholder={placeholder}
        style={{
          flex: 1,
          minWidth: 0,
          border: 'none',
          outline: 'none',
          background: 'transparent',
          fontFamily: 'var(--font-body)',
          fontSize: 'var(--body-lg-size)',
          color: 'var(--on-surface)',
        }}
        {...rest}
      />
    </div>
  );
}
