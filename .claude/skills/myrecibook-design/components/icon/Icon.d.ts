/**
 * Material Symbols Rounded glyph. MyReciBook's only icon system —
 * never hand-roll SVGs or use emoji as icons.
 */
export interface IconProps {
  /** Glyph name, e.g. "menu_book", "schedule", "favorite" */
  name: string;
  /** Font size in px. Default 24 (app default); 22 in the nav bar, 15–20 in chips/rows */
  size?: number;
  /** Variable weight 300–700. Default 400 */
  weight?: number;
  /** Filled axis — use for active/selected states (favorite heart, active tab) */
  fill?: boolean;
  /** CSS color. Default currentColor */
  color?: string;
  style?: React.CSSProperties;
}
export declare function Icon(props: IconProps): JSX.Element;
