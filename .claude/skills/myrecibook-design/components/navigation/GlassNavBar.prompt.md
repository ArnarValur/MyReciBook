Floating frosted-glass pill nav bar — 56px pill, 20px blur, 4 tabs split 2+2 around the gradient FAB. The shell's one fixed element; lists scroll under it (give them ~110px bottom padding).

```jsx
<div style={{ position: 'relative', width: 360, height: 780, overflow: 'hidden' }}>
  …screen content…
  <GlassNavBar active={0} onTab={setTab} onFab={openImport}
    items={[
      { icon: 'menu_book', label: 'Cookbook', logo: true },
      { icon: 'checklist', label: 'Grocery' },
      { icon: 'download', label: 'Queue', badge: 2 },
      { icon: 'settings', label: 'Settings' },
    ]} />
</div>
```

Canonical order: Cookbook · Grocery · [FAB] · **slot 3** · Settings — slot 3 is feature-flagged and renders Food, Pantry, Unlock, or Queue depending on which flag is live. The Cookbook tab draws the LogoMark (book only, `logo: true`) so tab and app icon read as one mark. Active tab = primary + filled axis; a primary Badge carries the imports-needing-attention count (zero hides it). The FAB is the import door from every tab.
