/**
 * Editor cover slot: chosen photo with a "change" glass pill, or the
 * "Add a cover photo" affordance. The camera/gallery sheet is the screen's.
 */
export interface CoverPickerFieldProps {
  /** The chosen photo URL; null/omit for the empty slot */
  src?: string | null;
  /** Slot height in px. Default 140 */
  height?: number;
  /** Opens the camera/gallery chooser */
  onClick?: () => void;
  style?: React.CSSProperties;
}
export declare function CoverPickerField(props: CoverPickerFieldProps): JSX.Element;
