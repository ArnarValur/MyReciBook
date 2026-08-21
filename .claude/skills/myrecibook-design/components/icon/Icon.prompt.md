Material Symbols Rounded glyph wrapper — MyReciBook's only icon system (the Flutter app uses `Icons.*_rounded`); never hand-roll SVG icons or use emoji as glyphs.

```jsx
<Icon name="menu_book" size={26} color="var(--primary)" />
<Icon name="favorite" fill color="var(--tertiary-container)" />
```

Common glyphs: `menu_book` (wordmark/cookbook), `checklist` (grocery), `download` (queue), `settings`, `add`, `search`, `schedule` (time chip), `restaurant` (servings), `favorite`, `photo_library`, `photo_camera`, `edit`, `delete`, `swap_horiz` (cover⇄original flip), `timer`, `play_arrow`, `arrow_back`, `arrow_forward`, `chevron_right`, `close`, `check`, `check_circle`, `smartphone`, `add_to_drive`, `cloud`, `hourglass_top`, `push_pin`, `ios_share`, `event_repeat`.

`fill` marks active/selected (active nav tab, favorited heart).
