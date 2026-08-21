Editor cover slot — "Add a cover photo" affordance (surface-container-low, primary icon + label), or the chosen photo with an `edit · change` glass pill bottom-right.

```jsx
<CoverPickerField onClick={openPhotoSheet} />
<CoverPickerField src={photo} onClick={openPhotoSheet} />
```

Radius 12, default height 140. Backing out of the chooser must leave the cover alone — only an explicit "Remove photo" clears it.
