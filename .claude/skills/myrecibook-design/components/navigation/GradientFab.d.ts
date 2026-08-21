/**
 * The 52px gradient FAB — the app's import door, and its strongest
 * visual accent. One per screen, always.
 */
export interface GradientFabProps {
  /** Material Symbols name. Default "add" */
  icon?: string;
  onClick?: () => void;
  style?: React.CSSProperties;
}
export declare function GradientFab(props: GradientFabProps): JSX.Element;
