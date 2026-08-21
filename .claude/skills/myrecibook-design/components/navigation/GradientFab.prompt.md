The 52px gradient FAB — the import door and the app's strongest accent. 135° primary-container → primary, white `add`, Moody Blue glow.

```jsx
<GradientFab onClick={openImportSheet} />
```

Lives in the glass nav bar's center notch (GlassNavBar draws it for you), or floats alone bottom-center when no bar is present. Never more than one; never repurpose the gradient elsewhere.
