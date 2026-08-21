/**
 * Category chip row (pantry + Add-food). Selected = solid primary —
 * deliberately stronger than FilterChip's secondary-container.
 */
export interface CategoryChipRowProps {
  /** Ordered categories; label may include the category emoji ("🥦 Produce") */
  categories: Array<{ key: string; label: string; count?: number }>;
  /** Selected category key; null = "All" */
  active?: string | null;
  /** Called with the tapped key, or null for "All" */
  onSelect?: (key: string | null) => void;
  /** Default "All" */
  allLabel?: string;
  style?: React.CSSProperties;
}
export declare function CategoryChipRow(props: CategoryChipRowProps): JSX.Element;
