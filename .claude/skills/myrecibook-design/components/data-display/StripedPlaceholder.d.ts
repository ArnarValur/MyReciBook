/**
 * Diagonal 45° striped placeholder for user-screenshot slots
 * (recipe covers, heroes, import thumbs). The stripes are the design's
 * honest "your screenshot goes here" — never substitute stock imagery.
 */
export interface StripedPlaceholderProps {
  /** Optional centered Material Symbols glyph, 30px muted */
  icon?: string;
  /** CSS height. Default 100% (fills its container) */
  height?: number | string;
  style?: React.CSSProperties;
}
export declare function StripedPlaceholder(props: StripedPlaceholderProps): JSX.Element;
