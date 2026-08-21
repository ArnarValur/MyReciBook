/**
 * THE canonical destructive confirm (6f) — reuse verbatim for every
 * destructive action; don't draft new dialog shapes.
 */
export interface ConfirmDialogProps {
  open?: boolean;
  /** Asks the question: "Delete recipe?" */
  title: string;
  /** States what SURVIVES before what stops: '"Creamy garlic pasta" and its images will be removed.' */
  body: string;
  /** The filled error button repeats the verb. Default "Delete" */
  verb?: string;
  onCancel?: () => void;
  onConfirm?: () => void;
  style?: React.CSSProperties;
}
export declare function ConfirmDialog(props: ConfirmDialogProps): JSX.Element | null;
