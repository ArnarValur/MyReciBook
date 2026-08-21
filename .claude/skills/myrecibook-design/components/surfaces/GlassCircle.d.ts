/** 40px frosted-glass circular icon button for hero overlays. */
export interface GlassCircleProps {
  /** Material Symbols name, drawn at 20px */
  icon: string;
  /** Filled glyph axis (the favorited heart) */
  fill?: boolean;
  /** Icon color override — the favorite heart uses tertiary-container */
  iconColor?: string;
  onClick?: () => void;
  style?: React.CSSProperties;
}
export declare function GlassCircle(props: GlassCircleProps): JSX.Element;
