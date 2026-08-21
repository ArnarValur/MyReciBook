/** 48px pill search field on surface-container (cookbook home). */
export interface SearchBarProps {
  /** Default "Search your cookbook…" */
  placeholder?: string;
  value?: string;
  /** Called with the new string value */
  onChange?: (value: string) => void;
  style?: React.CSSProperties;
}
export declare function SearchBar(props: SearchBarProps): JSX.Element;
