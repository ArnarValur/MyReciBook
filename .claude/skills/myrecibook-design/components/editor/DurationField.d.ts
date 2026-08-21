/**
 * Editor duration pill: schedule icon + number field + min/hr unit toggle.
 * Reports total minutes; the unit word is a control, never typed.
 */
export interface DurationFieldProps {
  /** Pre-fill; whole hours show as hours (120 → "2" hr), else minutes */
  initialMinutes?: number | null;
  /** Total minutes after every edit or unit flip; null = no duration */
  onChanged?: (totalMinutes: number | null) => void;
  /** Placeholder. Default "25" */
  hint?: string;
  style?: React.CSSProperties;
}
export declare function DurationField(props: DurationFieldProps): JSX.Element;
