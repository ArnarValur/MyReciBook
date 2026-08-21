/**
 * The house card. Every card in the app is a TokenCard: white
 * (surface-container-lowest) fill, hairline border, blue-tinted elev-1 shadow.
 */
export interface TokenCardProps {
  /** CSS padding — number of px or a padding string. Default 12; cards use 12–16 */
  padding?: number | string;
  /** 12 for list cards, 16 for large cards (paywall price, cap meter, dialogs) */
  radius?: number;
  /** 1.5px primary border + glow — selected storage option, merge prompt, price card */
  selected?: boolean;
  /** Turn off the elev-1 shadow (rare) */
  shadow?: boolean;
  /** Fill override (e.g. flag tint) */
  color?: string;
  /** Border override (e.g. warning for a flagged title card) */
  borderColor?: string;
  children?: React.ReactNode;
  style?: React.CSSProperties;
}
export declare function TokenCard(props: TokenCardProps): JSX.Element;
