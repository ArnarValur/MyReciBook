Check-off row for ingredients & grocery items — 18px rounded checkbox, bold leading quantity, strikethrough when checked. Stack inside a `TokenCard padding="2px 14px"`; hairline separators come built in (`last` on the final row).

```jsx
<TokenCard padding="2px 14px">
  <IngredientRow text="400 g spaghetti" />
  <IngredientRow text="2 lemons" trailing="2 recipes" />
  <IngredientRow text="olive oil" staple last />
</TokenCard>
```

Checking off is ephemeral kitchen state — never persisted. `qtyBold(raw)` is exported for reuse anywhere a raw line renders.
