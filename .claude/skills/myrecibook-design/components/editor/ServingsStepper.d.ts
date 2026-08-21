/**
 * Editor servings stepper: stadium pill, −/+ around "N servings".
 * The word is rendered by the widget, never typed by the user.
 */
export interface ServingsStepperProps {
  value: number;
  onChange?: (value: number) => void;
  /** Clamp — onChange only fires inside the range. Defaults 1 / 99 */
  min?: number;
  max?: number;
  style?: React.CSSProperties;
}
export declare function ServingsStepper(props: ServingsStepperProps): JSX.Element;
