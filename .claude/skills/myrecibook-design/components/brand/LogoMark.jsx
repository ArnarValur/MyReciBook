import React from 'react';

let _maskSeq = 0;

/**
 * The MyReciBook logo mark — drawn (not an image) so it tints with the
 * scheme and stays crisp at any size. Geometry is a 1:1 transcription of
 * the app's LogoMark painter (108-unit design space; the spine is knocked
 * OUT of the book via mask so the mark sits on any background).
 * It is the app icon, the Cookbook tab icon, and the cover watermark —
 * the three read as one mark.
 */
export function LogoMark({ size = 24, color = 'var(--primary)', withSteam = true, style = {} }) {
  const [maskId] = React.useState(() => `rb-lm-${++_maskSeq}`);
  // Ink bounds in design space, stroke widths included (from the painter).
  const viewBox = withSteam ? '26 23 56 55' : '26 51 56 27';
  return (
    <svg
      width={size}
      height={size}
      viewBox={viewBox}
      preserveAspectRatio="xMidYMid meet"
      aria-hidden="true"
      style={{ display: 'block', flex: 'none', ...style }}
    >
      <mask id={maskId}>
        <rect x="0" y="0" width="108" height="108" fill="#fff"></rect>
        <line x1="54" y1="62" x2="54" y2="76" stroke="#000" strokeWidth="2.5" strokeLinecap="round"></line>
      </mask>
      <path
        d="M54 60 C47 53 36 51 26 53 L26 72 C36 70 47 72 54 78 C61 72 72 70 82 72 L82 53 C72 51 61 53 54 60 Z"
        fill={color}
        mask={`url(#${maskId})`}
      ></path>
      {withSteam && [45, 63].map((x) => (
        <path
          key={x}
          d={`M${x} 26 C${x - 5} 33 ${x + 5} 35 ${x} 42`}
          fill="none"
          stroke={color}
          strokeWidth="6"
          strokeLinecap="round"
        ></path>
      ))}
    </svg>
  );
}
