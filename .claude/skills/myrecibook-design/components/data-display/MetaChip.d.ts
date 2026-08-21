/** Stadium metadata chip with a primary-colored icon (time, servings). */
export interface MetaChipProps {
  /** Material Symbols name, 16px primary — schedule, restaurant */
  icon?: string;
  label: string;
  onClick?: () => void;
  style?: React.CSSProperties;
}
export declare function MetaChip(props: MetaChipProps): JSX.Element;
