Stadium segmented control — pill container with an elevated white active segment.

```jsx
<SegmentedControl options={['One recipe · 3 shots', '3 separate recipes']} value={mode} onChange={setMode} />
<SegmentedControl showCheck options={['System', 'Light', 'Dark']} value={theme} onChange={setTheme} />
```

Two forms in the app: the import sheet's batch decision (active label in primary) and Settings' theme picker (`showCheck` — check icon + hairline on the active pill).
