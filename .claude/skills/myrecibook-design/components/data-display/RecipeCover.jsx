import React from 'react';
import { LogoMark } from '../brand/LogoMark.jsx';

/** The six cover pairs, in hash-table order — do not reorder. */
export const COVER_GRADIENTS = [
  ['#3F51B5', '#24389C'], // indigo — the brand
  ['#4A5A8C', '#2C3557'], // slate blue
  ['#8E3B62', '#5B2340'], // plum
  ['#B4643C', '#7C3F24'], // terracotta
  ['#2E6F6A', '#1B4744'], // teal
  ['#5E7346', '#3B4A2B'], // olive
];

/** The app's stable title hash — NOT String.hashCode (must survive relaunches). */
export function coverSlot(title) {
  let sum = 0;
  for (let i = 0; i < title.length; i++) sum = (sum + title.charCodeAt(i) * 31) % 1000003;
  return sum % COVER_GRADIENTS.length;
}

/**
 * A recipe's cover: the picked image when there is one, otherwise a drawn
 * 135° gradient chosen deterministically from the title, watermarked with
 * the LogoMark at 22% white. Screenshots are NOT promoted to covers —
 * the originals stay one tap away behind the hero's provenance flip.
 */
export function RecipeCover({ src, title = '', style = {} }) {
  if (src) {
    return <img src={src} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block', ...style }} />;
  }
  const pair = COVER_GRADIENTS[coverSlot(title)];
  return (
    <div
      style={{
        width: '100%',
        height: '100%',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: `linear-gradient(135deg, ${pair[0]}, ${pair[1]})`,
        ...style,
      }}
    >
      <div style={{ height: '46%', maxWidth: '46%', aspectRatio: '1 / 1', opacity: 0.22 }}>
        <LogoMark size="100%" color="#ffffff" />
      </div>
    </div>
  );
}
