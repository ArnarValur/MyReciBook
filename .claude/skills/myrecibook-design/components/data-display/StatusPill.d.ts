/**
 * Quiet storage-status pill. Both states are deliberately quiet —
 * "Synced" is not a celebration and "On this phone" is not a warning.
 */
export interface StatusPillProps {
  /** Material Symbols name, 13px — smartphone, cloud_done */
  icon?: string;
  label: string;
  style?: React.CSSProperties;
}
export declare function StatusPill(props: StatusPillProps): JSX.Element;
