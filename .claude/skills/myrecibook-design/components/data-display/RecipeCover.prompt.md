A recipe's cover — the picked image, else a drawn 135° gradient chosen deterministically from the title (stable hash: a recipe keeps its color forever), watermarked with the LogoMark at 22% white.

```jsx
<div style={{ height: 106 }}><RecipeCover title="Creamy garlic pasta" /></div>
<div style={{ height: 210 }}><RecipeCover src={pickedPhoto} title="…" /></div>
```

Six pairs in hash order: indigo (brand), slate blue, plum, terracotta, teal, olive. Screenshots are deliberately NOT promoted to covers — they looked bad; originals live behind the hero's provenance flip. Use StripedPlaceholder only for "your screenshot" slots (import thumbs, originals), RecipeCover for covers.
