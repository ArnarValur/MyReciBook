/**
 * Stadium segmented control: pill container, active segment is a white
 * (surface-container-lowest) pill with the card shadow.
 */
export interface SegmentedControlProps {
  /** Strings, or { value, label } pairs */
  options: Array<string | { value: string; label: string }>;
  value: string;
  onChange?: (value: string) => void;
  /** Settings-style: check icon + hairline border on the active segment; label stays on-surface instead of primary */
  showCheck?: boolean;
  style?: React.CSSProperties;
}
export declare function SegmentedControl(props: SegmentedControlProps): JSX.Element;
