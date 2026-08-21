/**
 * A recipe's cover: picked image, else a title-derived 135° gradient
 * watermarked with the LogoMark at 22% white. Fills its container.
 */
export interface RecipeCoverProps {
  /** The picked cover photo URL; omit for the drawn gradient tile */
  src?: string;
  /** Recipe title — drives the stable gradient choice (same title = same color forever) */
  title?: string;
  style?: React.CSSProperties;
}
export declare function RecipeCover(props: RecipeCoverProps): JSX.Element;
/** The six gradient pairs in hash order: indigo, slate, plum, terracotta, teal, olive. */
export declare const COVER_GRADIENTS: string[][];
/** The app's stable title hash → gradient index. */
export declare function coverSlot(title: string): number;
