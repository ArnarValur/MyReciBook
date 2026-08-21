Category chip row — one widget for the pantry shelf and the Add-food drawer so "pick a category" reads the same on both ends.

```jsx
<CategoryChipRow
  active={cat} onSelect={setCat}
  categories={[
    { key: 'produce', label: '🥦 Produce', count: 12 },
    { key: 'dairy', label: '🧀 Dairy', count: 5 },
    { key: 'other', label: 'Other', count: 3 },
  ]} />
```

Selected = solid primary fill (vs FilterChip's secondary-container — cookbook filters and category picks are deliberately distinct). Labels carry counts after the name; category emoji render as text — the one emoji surface in the app. The row scrolls horizontally, bleeding off the edge.
