The drawn MyReciBook logo mark — open book with two steam wisps, one flat color, spine knocked out so it sits on any background. Never redraw or approximate it; this component IS the geometry.

```jsx
<LogoMark size={26} />
<LogoMark size={22} withSteam={false} />  {/* nav slots, rows — book only below ~24px */}
<LogoMark size="46%" color="#fff" style={{ opacity: 0.22 }} />  {/* cover watermark */}
```

Three canonical uses: app icon, Cookbook tab icon (book only, 22px), and the watermark on generated recipe covers (RecipeCover does this for you). Pairs with the wordmark: mark + "MyReciBook" PJS w800 in primary.
