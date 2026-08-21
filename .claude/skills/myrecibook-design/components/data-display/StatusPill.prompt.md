Quiet status pill — storage state ("On this phone" / "Synced"). Success-tinted fill, muted 11px text.

```jsx
<StatusPill icon="smartphone" label="On this phone" />
<StatusPill icon="cloud_done" label="Synced" />
```

Both states are equal citizens by design — local-only is a feature, not a warning. Never restyle one as an alert.
