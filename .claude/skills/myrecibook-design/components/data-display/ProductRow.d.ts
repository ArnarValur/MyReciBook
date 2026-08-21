/**
 * The ONE pantry product card, shared by the Pantry list and the diary's
 * Add-food picker. Radius 14, 38px thumb, kcal MetaChip trailing.
 */
export interface ProductRowProps {
  name: string;
  brand?: string;
  /** Package size string, e.g. "500 g" — joins brand with a middot */
  quantity?: string;
  /** Calories per 100 g/ml — renders a trailing MetaChip */
  kcal?: number;
  /** The user's own product photo URL; omit for the kitchen-icon tile */
  image?: string;
  onClick?: () => void;
  style?: React.CSSProperties;
}
export declare function ProductRow(props: ProductRowProps): JSX.Element;
