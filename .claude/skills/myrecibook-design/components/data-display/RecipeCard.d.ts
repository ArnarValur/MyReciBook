/**
 * Cookbook 2-column grid card. Cover = picked photo, else the
 * title-derived gradient tile (RecipeCover) — never a screenshot.
 */
export interface RecipeCardProps {
  title: string;
  /** "25 min · Serves 4" — raw strings joined with middots */
  meta?: string;
  /** Picked cover photo URL; omit for the drawn gradient cover */
  cover?: string;
  onClick?: () => void;
  style?: React.CSSProperties;
}
export declare function RecipeCard(props: RecipeCardProps): JSX.Element;
