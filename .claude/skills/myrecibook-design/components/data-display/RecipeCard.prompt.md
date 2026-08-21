Cookbook grid card — 2-column grid, 12px gaps, 106px cover, 2-line clamped title, muted meta line.

```jsx
<div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
  <RecipeCard title="Creamy garlic pasta" meta="25 min · Serves 4" />
  <RecipeCard title="Grandma's pancakes" meta="20 min" cover={pickedPhoto} />
</div>
```

No picked photo → the title-derived gradient cover with the LogoMark watermark (never a screenshot, never stock food photography). Same title = same color forever.
