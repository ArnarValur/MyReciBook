/**
 * Check-off row for ingredient and grocery lists inside a TokenCard.
 * Renders the raw line with the leading quantity bolded ("**400 g** spaghetti").
 */
export interface IngredientRowProps {
  /** The raw line verbatim — "400 g spaghetti", "2 cloves garlic, minced" */
  text: string;
  /** Checked = primary checkbox + strikethrough muted text (ephemeral kitchen state) */
  checked?: boolean;
  onToggle?: () => void;
  /** Small trailing caption — "2 recipes", "moved here by you" */
  trailing?: string;
  /** Grocery staples: dimmed row + "staple" tag */
  staple?: boolean;
  /** Last row in the card drops its separator */
  last?: boolean;
  style?: React.CSSProperties;
}
export declare function IngredientRow(props: IngredientRowProps): JSX.Element;
/** Helper: JSX with the leading quantity of a raw line bolded. */
export declare function qtyBold(raw: string): React.ReactNode;
