# MyReciBook — Design System

Source of truth: `docs/MyReciBook Flutter mockups/myrecibook-design-system/tokens/*.css`,
built against `docs/design/handoff.md`. Implemented in Flutter at
`app/lib/ui/theme.dart` (colors) and `app/lib/ui/widgets/skin.dart` (shared
components). If this file and the tokens disagree, the tokens win — update
this file to match, not the other way round.

Two themes ship: light "Stitch Slate" and dark "Midnight". Never pure black —
dark mode bottoms out at `#0F1117`, a deep navy. Toggle by system setting;
there is no in-app theme switch.

## Brand

- Seed color: `#3F51B5` (Material 3 tonal palette generator input).
- Wordmark: Plus Jakarta Sans, weight 800, colored `--primary`, tracking −0.02em.
- Icons: Material Symbols Rounded — the single icon system, no mixing.

## Typography

Two families. Plus Jakarta Sans carries display and headline text (rounded,
friendly, the wordmark's font). Inter carries everything you read line by
line — body, labels, captions. Both load from Google Fonts and are bundled
into the APK (no runtime fetch — a kitchen app shouldn't need network for
its own type).

| Style | Font | Size | Line height | Weight | Used for |
|---|---|---|---|---|---|
| Display | Plus Jakarta Sans | 29px | 1.15 | 700 | Big paywall/headline moments ("Pay once. Cook forever.") |
| Headline / large | Plus Jakarta Sans | 23px | 1.25 | 700 | Screen titles, recipe title |
| Headline / medium | Plus Jakarta Sans | 18px | 1.3 | 700 | Page header next to the back arrow |
| Body | Inter | 14px | 1.45 | 400 | Default reading text |
| Body / small | Inter | 13.5px | 1.5 | 400 | Secondary reading text |
| Caption | Inter | 12.5px | 1.5 | 400 | Sublines, `on-surface-variant` colored |
| Caption / small | Inter | 12px | — | 400 | Smallest supporting text |
| Eyebrow | Inter | 11px | — | 600 | Section labels, e.g. "INGREDIENTS · 8" — uppercase, tracked 0.9px |
| Mono | ui-monospace | 11.5px | 1.65 | 400 | File paths, install IDs, meter counts |

## Color

Material 3 tonal palette from seed `#3F51B5`. Primary is indigo, secondary
is a softer indigo, tertiary (magenta-pink) is reserved for accents like a
"one-time purchase" tag or the favorite heart — used sparingly, never as a
primary action color.

### Light — "Stitch Slate"

| Role | Hex | Notes |
|---|---|---|
| Primary | `#24389C` | Buttons, links, active states |
| On primary | `#FFFFFF` | Text/icons on primary |
| Primary container | `#3F51B5` | Filled chips, FAB gradient start |
| On primary container | `#CACFFF` | |
| Secondary | `#4D5A9C` | Secondary actions, icons |
| Secondary container | `#ABB7FF` | Merge-suggestion buttons, selected chip fill |
| Tertiary | `#88003B` | Reserved accents (favorite, one-time tag) |
| Tertiary container | `#B40050` | |
| Error | `#BA1A1A` | |
| Error container | `#FFDAD6` | |
| Scaffold | `#FAF8F0` | Warm cream — the background behind every screen |
| Surface | `#F9F9FC` | |
| Surface container lowest | `#FFFFFF` | Cards, sheets |
| Surface container | `#EEEEF0` | |
| Surface container highest | `#E2E2E5` | |
| On surface | `#1A1C1E` | Primary text |
| On surface variant | `#454652` | Secondary text |
| Outline | `#757684` | |
| Outline variant | `#C5C5D4` | Hairline base |
| Success | `#22C55E` | Theme-stable — same value in both themes |
| Warning | `#F59E0B` | Theme-stable |
| Info | `#3B82F6` | Theme-stable |

### Dark — "Midnight"

| Role | Hex | Notes |
|---|---|---|
| Primary | `#BAC3FF` | Light lavender — M3's dark-mode primary shift |
| On primary | `#071A86` | |
| Primary container | `#293CA0` | |
| On primary container | `#DEE0FF` | |
| Secondary | `#B9C3FF` | |
| Secondary container | `#354282` | |
| Tertiary | `#FFB1C1` | |
| Tertiary container | `#8F003F` | |
| Error | `#FFB4AB` | |
| Error container | `#93000A` | |
| Scaffold | `#0F1117` | Deep navy — never `#000000` |
| Surface | `#0F1117` | |
| Surface container lowest | `#0A0C11` | |
| Surface container | `#161922` | Cards, sheets |
| Surface container highest | `#262A36` | |
| On surface | `#E4E2E6` | Primary text |
| On surface variant | `#C5C5D4` | Secondary text |
| Outline | `#8F8F9E` | |
| Outline variant | `#454652` | Hairline base |

Success/warning/info keep the same hex in both themes — they're semantic,
not tonal.

### Derived tints

- Hairline: `outline-variant` at 50% opacity. Soft hairline: 35%.
- Glass fill (light): white at 55% opacity, blurred 20px. Glass fill (dark):
  black at 35% opacity. Used for the floating back/favorite/delete circles
  over a photo hero.
- Placeholder stripes: diagonal 45° stripe pattern mixing `secondary-container`
  into `surface`, at 45%/20% — stands in for a user's screenshot wherever
  real imagery is absent.

### State tints

- Dimmed / skipped: 60% opacity on the whole element.
- Needs review: 1.5px border in `warning` mixed 55% with transparent; text in
  `warning` mixed 55% with `on-surface`.
- Failed: same pattern in `error`.

## Spacing & layout

4px base grid.

| Token | Value | Use |
|---|---|---|
| `space-xs` | 4px | |
| `space-sm` | 8px | |
| `space-compact` | 12px | |
| `space-md` | 16px | |
| `space-lg` | 24px | |
| `space-xl` | 32px | |
| Screen margin | 20px | Side padding on every screen |
| Grid gutter | 12px | Recipe grid gap |

### Radius

| Token | Value | Use |
|---|---|---|
| `radius-xs` | 4px | |
| `radius-sm` | 8px | Buttons, thumbnails, inline inputs |
| `radius-md` | 12px | Row cards, grid tiles, notes |
| `radius-lg` | 16px | Feature cards (meter, price card) |
| `radius-xl` | 24px | Bottom sheets, dialogs |
| `radius-full` | pill | Search, chips, meta pills, stadium buttons, drawer rows |

### Borders

Hairline: 1px. Focus / selected: 1.5px.

## Elevation & shadow

Depth reads as tonal layers plus a soft shadow tinted with the primary
indigo — not gray. Dark mode drops the indigo tint and leans on surface
tinting instead, with shadows softened to plain black.

| Token | Light | Dark | Use |
|---|---|---|---|
| `elev-1` | `0 4px 10px rgba(36,56,156,.06)` | `0 2px 8px rgba(0,0,0,.4)` | Cards, buttons |
| `elev-2` | `0 8px 20px rgba(36,56,156,.12)` | `0 8px 20px rgba(0,0,0,.5)` | Phone frames, price card, modals |
| `elev-3` | `0 12px 32px rgba(36,56,156,.16)` | `0 12px 32px rgba(0,0,0,.6)` | Sheets, dialogs, drawer |

Glow (focus, active, selected, the FAB):

| Token | Light | Dark |
|---|---|---|
| `glow-primary` | `0 0 12px 2px rgba(63,81,181,.15)` | `0 0 12px 2px rgba(186,195,255,.18)` |
| `glow-fab` | `0 8px 16px 2px rgba(63,81,181,.45)` | `0 8px 18px 2px rgba(186,195,255,.3)` |

Glass blur: 20px standard, 24px strong (used behind floating circles and
the future nav bar).

## Motion

| Token | Duration | Use |
|---|---|---|
| `dur-fast` | 150ms | Micro-interactions, hover |
| `dur-normal` | 300ms | Standard transitions |
| `dur-slow` | 500ms | Deliberate, attention-drawing |

Easing: `standard` for general use, `decelerate` for things entering the
screen, `accelerate` for things leaving it.

## Components (where they live in code)

| Component | File | Notes |
|---|---|---|
| Theme (colors, text theme, component themes) | `app/lib/ui/theme.dart` | `RbColors` (both schemes), `RbTokens` ThemeExtension (shadows, glow, hairline, glass) |
| Shared primitives | `app/lib/ui/widgets/skin.dart` | `SectionLabel`, `TokenCard`, `MetaChip`, `StatusPill`, `GlassCircle`/`GlassPill`, `GradientFab`, `StripedPlaceholder`, `CoverImage` |
| Buttons | stadium shape, 48dp tall | Filled and outlined variants |
| Sheets | 24px top radius | Floating snackbars |
| FAB | `GradientFab`, 52dp | 135° gradient from `primary-container` to `primary`, glow shadow |

## Notes for future changes

- Any new color must fit the Material 3 role system (primary/secondary/
  tertiary/surface/error) — don't invent one-off hex values in a screen file.
- Success/warning/info stay identical across themes; everything else follows
  the light/dark pair above.
- If the mockup HTML in `docs/` changes, that wins over this file per project
  convention (newest wins) — update this file to match, then note the date.

*Last written: 2026-08-20, from the design system tokens dated 2026-08-06
(unchanged since) and the Flutter implementation in `app/lib/ui/theme.dart`.*
