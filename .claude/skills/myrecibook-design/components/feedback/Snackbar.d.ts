/**
 * Floating snackbar (Flutter SnackBarBehavior.floating, radius 12).
 * Calm receipts, never celebrations.
 */
export interface SnackbarProps {
  /** e.g. "Notes saved", "Removed from grocery" */
  message: string;
  /** Optional action label, inverse-primary */
  action?: string;
  onAction?: () => void;
  style?: React.CSSProperties;
}
export declare function Snackbar(props: SnackbarProps): JSX.Element;
