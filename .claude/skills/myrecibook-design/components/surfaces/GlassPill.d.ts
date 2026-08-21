/** Frosted-glass stadium pill (icon + 11.5px label) over image heroes. */
export interface GlassPillProps {
  /** Material Symbols name, 15px */
  icon: string;
  label: string;
  onClick?: () => void;
  style?: React.CSSProperties;
}
export declare function GlassPill(props: GlassPillProps): JSX.Element;
