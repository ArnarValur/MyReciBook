Stadium pill button matching the Flutter theme — one filled CTA per screen; tonal/outlined/text for the rest; danger only as a destructive-confirm verb.

```jsx
<Button fullWidth icon={<Icon name="play_arrow" size={20} />}>Start cooking</Button>
<Button variant="tonal" icon={<Icon name="playlist_add" size={20} />}>Grocery</Button>
<Button variant="outlined" size="sm">Connect</Button>
<Button variant="text">Cancel</Button>
<Button variant="danger">Delete</Button>
```

Buttons are 48px tall (`sm` = 36px), always full-radius. Labels are Inter 14 w600, sentence case ("Rescue as one recipe", never "RESCUE"). CTAs may end with `trailingIcon={<Icon name="arrow_forward" size={18} />}`.
