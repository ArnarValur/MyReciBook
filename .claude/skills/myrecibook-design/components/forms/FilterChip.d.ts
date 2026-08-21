/**
 * 36px stadium filter chip. Rows bleed to the screen edge —
 * the half-visible last chip is the scroll cue.
 */
export interface FilterChipProps {
  label: string;
  /** Material Symbols name, drawn at 15px in primary (or on-secondary-container when selected) */
  icon?: string;
  selected?: boolean;
  onClick?: () => void;
  style?: React.CSSProperties;
}
export declare function FilterChip(props: FilterChipProps): JSX.Element;
