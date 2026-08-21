/**
 * Stadium (pill) button, per the Flutter button themes: 48px filled CTAs,
 * 36px small actions. Never square corners.
 */
export interface ButtonProps {
  /**
   * filled — solid primary, the one main CTA per screen ("Save to cookbook"). 48px.
   * tonal — secondary-container, secondary actions ("Grocery", "Merge · 6 lemons").
   * outlined — 1.5px secondary border, 44px tall ("Connect", "Review flagged · 2").
   * text — quiet inline action ("Cancel", "Keep apart", "Save notes").
   * danger — solid error; ONLY as the destructive-confirm verb.
   */
  variant?: 'filled' | 'tonal' | 'outlined' | 'text' | 'danger';
  /** md = 48px (CTAs, hit-target floor 44); sm = 36px (in-card actions) */
  size?: 'md' | 'sm';
  /** Leading icon node, e.g. <Icon name="add" size={20} /> */
  icon?: React.ReactNode;
  /** Trailing icon node — CTAs often end with arrow_forward */
  trailingIcon?: React.ReactNode;
  fullWidth?: boolean;
  disabled?: boolean;
  onClick?: () => void;
  children?: React.ReactNode;
  style?: React.CSSProperties;
}
export declare function Button(props: ButtonProps): JSX.Element;
