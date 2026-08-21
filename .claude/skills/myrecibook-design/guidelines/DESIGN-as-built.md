# MyReciBook — Design System

**This document describes the skin as built.** Every value here was read out of
the shipping Flutter code, not the design brief. If you are taking this to a
design tool to polish the app, what you see below is what the app currently
renders on a device.

Where the code and the original design bundle disagree, this file follows the
code and records the disagreement in [Known gaps](#known-gaps) at the end.

**Implemented in:**

- `app/lib/ui/theme.dart` — both color schemes, the text theme, component themes, and `RbTokens` (shadows, glow, hairlines, glass)
- `app/lib/ui/widgets/skin.dart` — shared visual primitives
- `app/lib/ui/widgets/` — nav bar, chips, editor fields, logo, product rows

**Design origin (reference, superseded by the code above):**
`docs/design/handoff.md`, `docs/design/skin-implementation-map.md`, and the
token CSS in `docs/MyReciBook Flutter mockups/myrecibook-design-system/tokens/`.

Two themes ship: light **"Stitch Slate"** and dark **"Midnight"**. Dark mode
never bottoms out at pure black — the floor is `#0F1117`, a deep navy. The user
picks System, Light, or Dark from a segmented control in Settings; the choice
persists and drives `themeMode` live.

Reference frame: 360dp wide (Galaxy S21). All px values below are dp, 1:1.

---

## Brand

- **Seed color:** `#3F51B5` ("Moody Blue") — the Material 3 tonal palette input.
- **Wordmark:** Plus Jakarta Sans 800, colored `primary`, tracking −0.02em.
- **Logo mark:** `LogoMark` (`app/lib/ui/widgets/logo_mark.dart`) — a drawn book
  glyph. It is the app icon, the Cookbook tab icon, and the watermark on
  generated recipe covers, so the three read as one mark.
- **Icons:** Flutter's built-in Material Icons, **rounded variants only**
  (`Icons.*_rounded`). Selected and active states use the icon `fill` axis
  (`fill: 1`) rather than a different glyph. No emoji-as-icon, no custom SVG.

---

## Color

Material 3 tonal palettes from seed `#3F51B5`. Primary is indigo, secondary a
softer indigo. Tertiary (magenta-pink) is **reserved** — it appears only on the
paywall's ONE-TIME badge and the favorite heart, never as a general action color.

### Light — "Stitch Slate"

| Role | Hex | Notes |
|---|---|---|
| Primary | `#24389C` | Buttons, links, active tab, selected borders |
| On primary | `#FFFFFF` | |
| Primary container | `#3F51B5` | FAB gradient start (see note below) |
| On primary container | `#CACFFF` | |
| Secondary | `#4D5A9C` | Outlined-button borders, secondary icons |
| On secondary | `#FFFFFF` | |
| Secondary container | `#ABB7FF` | Selected chip fill, placeholder stripes |
| On secondary container | `#394687` | |
| Tertiary | `#88003B` | Reserved — favorite heart, ONE-TIME badge |
| On tertiary | `#FFFFFF` | |
| Tertiary container | `#B40050` | |
| On tertiary container | `#FFC3CE` | |
| Error | `#BA1A1A` | Destructive confirm button fill |
| On error | `#FFFFFF` | |
| Error container | `#FFDAD6` | |
| On error container | `#93000A` | |
| **Scaffold** | `#FAF8F0` | Warm cream — the background behind every screen |
| Surface | `#F9F9FC` | |
| Surface dim | `#DADADC` | |
| Surface bright | `#F9F9FC` | |
| Surface container lowest | `#FFFFFF` | **Cards, sheets, dialogs** |
| Surface container low | `#F3F3F6` | |
| Surface container | `#EEEEF0` | |
| Surface container high | `#E8E8EA` | Meta chips, icon circles |
| Surface container highest | `#E2E2E5` | |
| On surface | `#1A1C1E` | Primary text |
| On surface variant | `#454652` | Secondary text, inactive tabs |
| Outline | `#757684` | Dashed info-card border (at 60%) |
| Outline variant | `#C5C5D4` | Hairline base |
| Inverse surface | `#2F3133` | |
| On inverse surface | `#F0F0F3` | |
| Inverse primary | `#BAC3FF` | |
| Surface tint | `#4355B9` | |

Note: the scaffold (`#FAF8F0`, warm) is deliberately **not** the same as surface
(`#F9F9FC`, cool). Cards sit at pure white on warm cream — that contrast is the
signature of the light theme.

Note: `primaryContainer` is a mid-dark indigo with a **light** on-color, which
inverts the usual Material 3 light-mode pattern (light container, dark
on-color). `secondaryContainer` follows the usual pattern. This is intentional —
`primaryContainer` exists mainly to be the FAB gradient's dark end — but it
means stock Material widgets that default to `primaryContainer` as a background
will read as a dark block. Reach for `secondaryContainer` when you want a
tonal fill.

### Dark — "Midnight"

| Role | Hex | Notes |
|---|---|---|
| Primary | `#BAC3FF` | Light lavender — the M3 dark-mode primary shift |
| On primary | `#071A86` | |
| Primary container | `#293CA0` | |
| On primary container | `#DEE0FF` | |
| Secondary | `#B9C3FF` | |
| On secondary | `#21326F` | |
| Secondary container | `#354282` | |
| On secondary container | `#DEE1FF` | |
| Tertiary | `#FFB1C1` | |
| On tertiary | `#650029` | |
| Tertiary container | `#8F003F` | |
| On tertiary container | `#FFD9DF` | |
| Error | `#FFB4AB` | |
| On error | `#690005` | |
| Error container | `#93000A` | |
| On error container | `#FFDAD6` | |
| **Scaffold** | `#0F1117` | Deep navy — never `#000000` |
| Surface | `#0F1117` | |
| Surface dim | `#0F1117` | |
| Surface bright | `#35373E` | |
| Surface container lowest | `#0A0C11` | |
| Surface container low | `#141720` | |
| Surface container | `#161922` | Cards, sheets |
| Surface container high | `#1C1F2B` | Chips |
| Surface container highest | `#262A36` | |
| On surface | `#E4E2E6` | Primary text |
| On surface variant | `#C5C5D4` | Secondary text |
| Outline | `#8F8F9E` | |
| Outline variant | `#454652` | Hairline base |
| Inverse surface | `#E4E2E6` | |
| On inverse surface | `#2F3133` | |
| Inverse primary | `#24389C` | |
| Surface tint | `#BAC3FF` | |

In dark mode, depth reads as **surface tinting**, not shadow. Cards step up
through the `surfaceContainer*` ladder rather than casting stronger shadows.

### Semantic colors

Two ship, defined outside the color scheme in `RbColors` and identical in both
themes:

| Token | Hex | Where |
|---|---|---|
| `success` | `#22C55E` | "Recipe rescued ✓" check, done badges, StatusPill background at 14% |
| `warning` | `#F59E0B` | Flagged-row tint, needs-review borders |

**Contrast rule — read this before using them as text.** Both are tuned for the
dark theme and are too light to sit directly on light surfaces: `#22C55E` on the
cream scaffold is 2.1:1, `#F59E0B` is 2.0:1. The codebase never uses them as raw
text. Established pattern, keep it:

- **Fill:** the raw color at 12–14% alpha.
- **Border:** the raw color at 55–70% alpha, 1.5px.
- **Text:** `Color.alphaBlend(warning @ 55%, onSurface)` — blend toward the text
  color so it stays readable.
- **Icon:** the only raw usage is a small success check that always sits beside
  text saying the same thing. Don't add icon-only meanings in these colors.

### Derived tints

| Token | Light | Dark |
|---|---|---|
| Hairline | `outlineVariant` @ 50% → `#80C5C5D4` | `#80454652` |
| Separator (soft hairline) | `outlineVariant` @ 35% → `#59C5C5D4` | `#59454652` |
| Glass fill | white @ 55% → `#8CFFFFFF` | black @ 35% → `#59000000` |
| Glass border | black @ 8% → `#14000000` | white @ 12% → `#1FFFFFFF` |

**Placeholder stripes** — 45° diagonal stripes, 8px wide alternating, mixing
`secondaryContainer` into `surface` at 45% and 20%. Stands in wherever a user
screenshot would render but none exists. Drawn by `StripedPlaceholder`.

**Recipe cover gradients** — when a recipe has no picked image, the cover is a
drawn 135° gradient chosen deterministically from the recipe title (a stable
hash, so a recipe keeps its color across launches), watermarked with `LogoMark`
at 22% white. Six pairs:

| Name | From | To |
|---|---|---|
| Indigo (brand) | `#3F51B5` | `#24389C` |
| Slate blue | `#4A5A8C` | `#2C3557` |
| Plum | `#8E3B62` | `#5B2340` |
| Terracotta | `#B4643C` | `#7C3F24` |
| Teal | `#2E6F6A` | `#1B4744` |
| Olive | `#5E7346` | `#3B4A2B` |

Screenshots are deliberately **not** promoted to covers — they looked bad. The
originals stay one tap away behind the hero's provenance flip.

### State treatments

| State | Treatment |
|---|---|
| Selected (card) | 1.5px `primary` border + `glowPrimary`, replacing the normal shadow |
| Needs review | 1.5px border in `warning` @ 55%; row background `warning` @ 12%; text blended `warning` @ 55% over `onSurface` |
| Failed | Same shape as needs-review, in `error` |
| Dimmed / skipped | 60% opacity on the whole element |
| Checked ingredient | Strikethrough — ephemeral kitchen state, never persisted |

---

## Typography

Two families, both **bundled into the APK** as assets under `app/google_fonts/`
with their OFL licenses registered at startup. `GoogleFonts.config.allowRuntimeFetching`
is set to `false` in `main()` and again in the test harness — the skin renders
correctly offline and in tests, and a kitchen app never waits on the network for
its own type.

Bundled weights: **Plus Jakarta Sans** 400/600/700/800 · **Inter** 400/500/600/700.

Plus Jakarta Sans carries display, headline, and title. Inter carries everything
read line by line — body and labels.

### The scale as built

These are the Flutter `TextTheme` slots. Letter spacing is in logical pixels
(the em equivalent is noted where it's meaningful).

| Slot | Font | Size | Weight | Tracking | Used for |
|---|---|---|---|---|---|
| `displayLarge` | Plus Jakarta Sans | 48 | 700 | −0.96 (−0.02em) | *Defined, never used* |
| `headlineLarge` | Plus Jakarta Sans | 32 | 600 | −0.32 (−0.01em) | *Defined, never used* |
| `headlineMedium` | Plus Jakarta Sans | 26 | 700 | −0.52 (−0.02em) | Hero headlines ("Pay once. Cook forever."), cook-mode step text |
| `headlineSmall` | Plus Jakarta Sans | 23 | 700 | −0.23 (−0.01em) | **Screen titles, recipe title** |
| `titleLarge` | Plus Jakarta Sans | 18 | 700 | — | **App bar title**, page header next to the back arrow |
| `titleMedium` | Plus Jakarta Sans | 15 | 600 | — | Card titles |
| `titleSmall` | Inter | 13.5 | 600 | — | Small card titles, row headings |
| `bodyLarge` | Inter | 14 | 400 | — | **Default reading text** |
| `bodyMedium` | Inter | 13.5 | 400 | — | Secondary reading text |
| `bodySmall` | Inter | 12 | 400 | — | Smallest supporting text |
| `labelLarge` | Inter | 14 | 600 | — | **All button text** |
| `labelMedium` | Inter | 12.5 | 500 | — | Chip labels, captions |
| `labelSmall` | Inter | 11 | 600 | 0.9 | **Section eyebrows** (`INGREDIENTS · 8`) — uppercased by `SectionLabel` |

One-off sizes that live in screens rather than the theme: cook-mode step text
**27sp** centered at 1.4 (the floor for arm's-length reading is 24sp), settings
screen title 22, glass-pill labels 11.5, dashed info-card body 12.5 at 1.5.

**Line height is not set on the theme slots** — Material's per-slot defaults
apply. The original design called for 1.45–1.5 on body text; a few screens set
it inline (cook-mode step 1.4, unlock body 1.4, dashed info card 1.5) but most
don't. Treat line height as an open item, not a rule the app follows.

Monospace is used for file paths, install IDs, and meter counts at ~11.5, via
the platform default (`ui-monospace`). It is not a theme slot.

---

## Voice and copy

Part of the skin, and easy to break:

- English, playful, **sentence case everywhere** — buttons included ("Save to
  cookbook", not "Save To Cookbook").
- ALL-CAPS **only** for the tiny tracked section eyebrows. `SectionLabel`
  uppercases for you; don't type caps into a string.
- Say what survives before what stops. The destructive confirm dialog states
  what is kept, then what is removed.
- Product promises stay quiet — the dashed info card, not a banner.

---

## Spacing and layout

4px base grid.

| Token | Value |
|---|---|
| `space-xs` | 4 |
| `space-sm` | 8 |
| `space-compact` | 12 |
| `space-md` | 16 |
| `space-lg` | 24 |
| `space-xl` | 32 |

Layout rules:

| Rule | Value |
|---|---|
| Screen side margin | 20 |
| Recipe grid gutter | 12 |
| Card internal padding | 12 (default) to 16 |
| Gap between stacked cards | 11–12 |
| Section eyebrow → card gap | 12 |
| Minimum hit target | 44 (cook mode uses 60dp whole-zone targets) |

### Radius

| Token | Value | Use |
|---|---|---|
| `radius-xs` | 4 | Rare |
| `radius-sm` | 8 | Small inputs, inline tints, thumbnails |
| `radius-md` | 12 | **The workhorse** — row cards, grid tiles, notes, snackbars |
| `radius-lg` | 16 | Feature cards, **dialogs** |
| Icon squircle | 22 | Icon tiles |
| `radius-xl` | 24 | Bottom sheets (top corners only) |
| `radius-full` | 999 | **The other workhorse** — search, chips, meta pills, segmented control, stadium buttons, FAB |

In practice the app is overwhelmingly pill and 12, with 8 for small inputs.
16, 22, and 24 are rare and specific. Reaching for anything else is a smell.

### Borders

Hairline 1px. Focus, selected, and flagged 1.5px.

---

## Elevation, shadow, and glass

Depth in light mode is a soft shadow tinted with the primary indigo — never
gray. Dark mode drops the tint, softens to plain black, and leans on surface
tinting instead.

| Token | Light | Dark | Use |
|---|---|---|---|
| `cardShadow` | `0 4px 10px rgba(36,56,156,.06)` | `0 2px 8px rgba(0,0,0,.4)` | Cards, buttons |
| `modalShadow` | `0 8px 20px rgba(36,56,156,.12)` | `0 8px 20px rgba(0,0,0,.5)` | Modals, price card, phone frames |

| Glow | Light | Dark | Use |
|---|---|---|---|
| `glowPrimary` | `0 0 12px 2px rgba(63,81,181,.15)` | `0 0 12px 2px rgba(186,195,255,.18)` | Focus, selected cards, merge prompt |
| `glowFab` | `0 8px 16px 2px rgba(63,81,181,.45)` | `0 8px 18px 2px rgba(186,195,255,.3)` | The FAB only |

Glass: `BackdropFilter` with sigma **12** on the floating circles and pills over
photo heroes, sigma **20** on the nav bar. Fill and border come from the derived
tints table above, plus a 1px hairline.

---

## Motion

| Token | Duration | Use |
|---|---|---|
| Fast | 150ms | Micro-interactions |
| Normal | 300ms | Standard transitions |
| Slow | 500ms | Deliberate, attention-drawing |

Easing: `cubic-bezier(0.2, 0, 0, 1)` standard · `cubic-bezier(0.05, 0.7, 0.1, 1)`
for things entering · `cubic-bezier(0.3, 0, 0.8, 0.15)` for things leaving.
**No bouncy curves.**

---

## Components

### Theme-level (`app/lib/ui/theme.dart`)

| Component | As built |
|---|---|
| App bar | Scaffold-colored, zero elevation, no surface tint, left-aligned, `titleLarge` title, 22dp icons |
| Filled button | Stadium, minimum 48×48, `labelLarge` |
| Outlined button | Stadium, minimum 48×44, 1.5px `secondary` border, `labelLarge` |
| Text button | `labelLarge` at 13 |
| Bottom sheet | `surfaceContainerLowest`, 24 top radius, no surface tint |
| Dialog | `surfaceContainerLowest`, 16 radius, no surface tint |
| Snackbar | Floating, 12 radius |
| Progress indicator | `primary`, 6dp linear track |

### Shared primitives (`app/lib/ui/widgets/skin.dart`)

| Widget | As built |
|---|---|
| `SectionLabel` | Uppercased `labelSmall` in `onSurfaceVariant`, optional trailing widget |
| `TokenCard` | `surfaceContainerLowest`, hairline border, 12 radius, 12 padding, `cardShadow`. `selected: true` → 1.5px `primary` + `glowPrimary` |
| `MetaChip` | Stadium on `surfaceContainerHigh`, 13×7 padding, optional 16dp `primary` icon, `labelMedium` |
| `StatusPill` | Quiet storage badge — stadium on `success` @ 14%, 13dp icon, `labelSmall` in `onSurfaceVariant` |
| `AppBackButton` | The one back button — `arrow_back_rounded`, tooltip "Back". Flutter's `BackButton` forces the platform glyph, so this stays ours |
| `GlassCircle` | 40dp frosted circle, blur 12, 20dp icon, `fill` axis for active. Tooltip doubles as the TalkBack label |
| `GlassPill` | Frosted stadium, blur 12, 15dp icon + 11.5 label — the "original ⇄ cover" flipper |
| `GradientFab` | 52dp, 135° `primaryContainer` → `primary`, `glowFab`, `onPrimary` icon. Wraps a real `FloatingActionButton` so tests keep working |
| `StripedPlaceholder` | The 45° stripe painter |
| `DashedInfoCard` | Soft `outline` @ 60% border, 12 radius, 12.5 body at 1.5 |
| `RecipeCover` | Picked image, else a title-derived gradient with the logo watermark |
| `CoverImage` | `Image.file` with a stripe fallback on missing or unreadable |
| `OriginalsViewer` | Full-screen black pinch-zoom `PageView` over the source screenshots — the provenance affordance |
| `showDestructiveConfirm` | **The** destructive dialog. Title asks the question, body states what survives before what stops, actions are a text "Cancel" plus a filled `error` button repeating the verb. Reuse verbatim; don't draft new destructive shapes |
| `qtyBoldSpan` | Bolds a leading quantity ("**400 g** spaghetti"); plain when no amount is found |

### Other widgets

| Widget | File |
|---|---|
| `GlassNavBar` | `widgets/glass_nav_bar.dart` |
| `LogoMark` | `widgets/logo_mark.dart` |
| Category chips | `widgets/category_chips.dart` |
| Editor fields | `widgets/editor_fields.dart` |
| Product picker sheet | `widgets/product_picker_sheet.dart` |
| Product row | `widgets/product_row.dart` |

---

## App shell

Floating glass nav bar, shipped in `app_shell.dart`: a 56dp pill inside a 64dp
hint (the FAB overhangs), sitting 16dp above the bottom edge, with the host
scaffold setting `extendBody: true` so content scrolls under the glass.

Four tabs split 2 + 2 around the center FAB: **Cookbook** · **Grocery** ·
[FAB] · **slot 3** · **Settings**. Slot 3 is feature-flagged — it renders as
Food, Pantry, Unlock, or Queue depending on which flag is live.

Selected tab is `primary` with the icon `fill` axis on; unselected is
`onSurfaceVariant`, 22dp, with a 2dp gap to the label. Cookbook draws the
`LogoMark` instead of a Material glyph so the tab and the app icon are one
mark. A `Badge.count` in `primary` carries the count of imports needing
attention; zero hides it.

The FAB is the import door from every tab.

---

## Adding to this system

- **Any new color must map to an existing role** — primary, secondary, tertiary,
  surface, error, or one of the two semantic colors. Don't put a one-off hex in
  a screen file. If you truly need a new value, add it to `RbColors` or
  `RbTokens` and add it here.
- **Reach for `secondaryContainer`, not `primaryContainer`,** for tonal fills.
  See the note under the light palette.
- **`success` and `warning` are fills and borders**, not text colors. Blend them
  toward `onSurface` when they must carry words.
- **Tertiary stays reserved.** Favorite heart and the ONE-TIME badge, nothing else.
- **Radius: pill or 12** unless you have a specific reason.
- **New destructive confirms reuse `showDestructiveConfirm`.** No new shapes.
- **Icons are `Icons.*_rounded`,** with the fill axis for selected states.
- When you change the skin, update this file in the same commit, and move the
  item out of Known gaps if you closed one.

---

## Known gaps

Things the original design bundle specifies that the app does **not** currently
do. None of these are bugs in the design — they're drift, listed so nobody
designs against a token that isn't there.

| Gap | Detail |
|---|---|
| No `info` color | The design bundle defines `info` `#3B82F6`. `RbColors` never declares it, and nothing uses it. Only `success` and `warning` exist in the app. |
| No third elevation step | The bundle defines `elev-3` (`0 12px 32px`) for sheets, dialogs, and drawers. `RbTokens` implements only `cardShadow` and `modalShadow`; sheets and dialogs currently carry no custom shadow. |
| Glass blur is lighter than specified | The bundle calls for 20px standard and 24px strong. The floating circles and pills blur at 12; the nav bar at 20. Nothing uses 24. |
| Reduced motion not respected | The design brief says to honor the system reduced-motion setting. Nothing in the app checks `MediaQuery.disableAnimations`. |
| Six icons miss the rounded variant | `Icons.add`, `Icons.barcode_reader`, `Icons.description_outlined`, `Icons.flag_outlined` — 6 call sites out of 161. The other 155 follow the rule. |
| Outlined buttons are 44 tall, not 48 | Filled buttons are 48×48; outlined are 48×44. Still above the 44dp hit-target floor, but the two don't match. |
| Body line heights unset | The bundle specifies 1.45–1.5 on body text. The Flutter text theme sets sizes and weights but no line heights, so Material defaults apply. |
| Dialog radius disagreement | The token CSS comments say bottom sheets and dialogs share 24. `handoff.md` says dialogs are 16, and the app renders 16. This file follows the app. If you want 24, that's a code change plus a note here. |

---

*Normalized from the shipping code on 2026-08-20, at version 0.10.0+8. Design
bundle dated 2026-08-06, unchanged since. When code and this file drift, the
code is the truth — re-read `theme.dart` and `skin.dart` and update here.*
