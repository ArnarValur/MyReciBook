/**
 * The app shell's floating frosted-glass pill nav: 4 tabs (2+2) around
 * the center gradient FAB — Cookbook · Grocery · [FAB] · slot 3 · Settings.
 * Slot 3 is feature-flagged (Food / Pantry / Unlock / Queue). Position it
 * inside a relatively-positioned screen frame; content scrolls underneath
 * (110px bottom clearance).
 */
export interface GlassNavBarProps {
  /** Default: Cookbook (LogoMark) / Grocery / [FAB] / Queue / Settings.
   * `logo: true` draws the LogoMark (book only) instead of the icon — the Cookbook tab. */
  items?: Array<{ icon: string; label: string; badge?: number; logo?: boolean }>;
  /** Active tab index 0–3 (filled icon + primary tint) */
  active?: number;
  onTab?: (index: number) => void;
  /** The FAB — opens the import sheet from every tab */
  onFab?: () => void;
  style?: React.CSSProperties;
}
export declare function GlassNavBar(props: GlassNavBarProps): JSX.Element;
