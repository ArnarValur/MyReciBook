/** The one back button — arrow_back rounded at 22px in a 44px target. */
export interface AppBackButtonProps {
  onClick?: () => void;
  /** Default var(--on-surface) */
  color?: string;
  style?: React.CSSProperties;
}
export declare function AppBackButton(props: AppBackButtonProps): JSX.Element;
