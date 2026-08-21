/**
 * `INGREDIENTS · 8` — the tiny tracked uppercase label above every
 * card/section. The ONLY ALL-CAPS text in the app.
 */
export interface SectionLabelProps {
  /** Label text; counts join with a middot: "Ingredients · 8" */
  children: React.ReactNode;
  /** Optional trailing node — e.g. the "your aisle" pin pill */
  trailing?: React.ReactNode;
  style?: React.CSSProperties;
}
export declare function SectionLabel(props: SectionLabelProps): JSX.Element;
