THE canonical destructive confirm — the one dialog shape; reuse it verbatim for any destructive action.

```jsx
<ConfirmDialog
  title="Delete recipe?"
  body={'"Creamy garlic pasta" and its images will be removed.'}
  verb="Delete"
  onCancel={close} onConfirm={doDelete} />
```

Rules baked into the shape: the title asks the question; the body states what survives before what stops; actions are text Cancel + a filled error button repeating the verb. Radius 16, elev-2, over the 45% scrim. Positioned `absolute` — mount inside the screen frame.
