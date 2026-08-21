/**
 * The drawn MyReciBook logo mark (open book + steam wisps). App icon,
 * Cookbook tab icon, and the watermark on generated recipe covers.
 */
export interface LogoMarkProps {
  /** Side of the square box the mark fits into (px number or CSS string, e.g. '100%'). Default 24 */
  size?: number | string;
  /** CSS color — the mark is one flat color. Default var(--primary) */
  color?: string;
  /** Full mark (book + steam) for headers/splash. false = book only — below ~24px the wisps turn to mush, so nav slots and rows drop them. Default true */
  withSteam?: boolean;
  style?: React.CSSProperties;
}
export declare function LogoMark(props: LogoMarkProps): JSX.Element;
