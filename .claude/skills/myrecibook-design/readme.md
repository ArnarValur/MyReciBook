# MyReciBook Design System

The design system for **MyReciBook** — a pay-once Android recipe app by
**Merkurial-Studio** (the company behind DittoDatto) that rescues recipes out
of screenshots, links and handwritten cards into plain JSON files the user
owns. No subscription, no account, no server. AI extraction is metered by a
yearly fair-use cap (600/yr working number); typing recipes in is always
unlimited.

> **Pitch:** *"Rescue the recipes buried in your camera roll."*
> **Pricing:** *"Pay once. Cook forever."* ($24.99 one-time, working number)

It shares Merkurial-Studio's house visual language with the **DittoDatto**
design system (Moody Blue M3 palette, PJS+Inter, glass, blue-tinted shadows)
— but the copy voice is English & playful (DittoDatto is Norwegian), and the
component inventory is MyReciBook's own.

**Normalized against the as-built skin** (v0.10.0+8, 2026-08-20): every value
here matches `guidelines/DESIGN-as-built.md` — the reviewed as-built spec —
which wins over the older design bundle wherever they disagree.

## Products

One product: the **Android app** (Flutter, Material 3, 360dp reference frame
= Galaxy S21). Light "Stitch Slate" (default, warm cream) and dark "Midnight"
(deep navy, never black) both ship; theme picked in Settings, persists. Beyond
the cookbook core, feature-flagged tabs exist for Grocery, Pantry, Food diary
and Unlock. → UI kit recreation planned in `ui_kits/android_app/`.

## Sources this system was built from

Nothing here was invented; consult these if you have access:

- **`guidelines/DESIGN-as-built.md`** — the reviewed as-built design spec
  (copied from the repo), including the Known gaps list. Read it first.
- **`ui/` mounted codebase** = `app/lib/ui/` of the repo: `theme.dart`
  (RbColors/RbTokens — token source of truth), `widgets/skin.dart` (shared
  primitives), `widgets/logo_mark.dart` (the drawn mark), `widgets/`
  (glass_nav_bar, category_chips, editor_fields, product_picker_sheet,
  product_row), and every screen (recipe list/detail, cook mode, import
  sheet/review, batch queue, grocery, pantry, diary, plan, unlock, storage,
  settings, manual entry).
- **GitHub: [ArnarValur/MyReciBook](https://github.com/ArnarValur/MyReciBook)**
  — `docs/design/handoff.md` (the original hi-fi spec),
  `docs/design/skin-implementation-map.md`, `CLAUDE.md` (strategy),
  `app/google_fonts/` (the bundled TTFs copied into `assets/fonts/`).
  Explore the repo to build better MyReciBook designs.
- **DittoDatto design system** (sibling project) — the shared house palette.

## CONTENT FUNDAMENTALS

**Language.** English. Playful but precise; every promise is verifiable.

**Casing.** Sentence case *everywhere*, buttons included ("Save to cookbook",
"Rescue as one recipe"). ALL-CAPS only for tiny tracked section eyebrows
("INGREDIENTS · 8" — SectionLabel uppercases for you; never type caps into a
string) and the ONE-TIME badge.

**Voice.** Second person, warm, a little wry — never salesy, never guilt.
The house verb is **rescue** (not scan/import/digitize). Failures are calm
and generous; the app takes the blame ("We read it twice and couldn't find a
recipe"), then reassures: gallery untouched, nothing deleted, cap unspent.
Say **what survives before what stops** — the destructive dialog's rule.
Product promises stay quiet — the dashed info card, not a banner.

**The promise register** — trust copy states what the user keeps:
- "Pay once. Cook forever." / "No subscription. No account. Ever."
- "Because your recipe box shouldn't have a landlord. You buy MyReciBook like you'd buy a good knife: once."
- "If MyReciBook vanished tomorrow, your recipes wouldn't."
- "Typing or pasting recipes in yourself is always unlimited — the cap only meters the AI."
- "600 AI rescues a year — fair-use cap, in writing."

**Tone examples (verbatim):**
- Empty book: "Your book is empty (for now)" / "Somewhere in your camera roll, a pile of recipes is waiting to be rescued." → CTA "Rescue your first recipe"
- Extraction failed: "That one kept its secrets" (reserved for genuine no-recipe reads; offline → "You're offline", rate-limit → "Give it a minute")
- Cap reached: "You've rescued a lot this year" — kept-promise framing, resets 1 January
- Batch queue: "1 needs your eyes" · "Not a recipe? We skip it and say so — no junk lands in your book."
- Import sheet: "Add to your book" · camera row "cookbook or grandma's card — handwriting welcome" · manual row "no AI, no cap — always unlimited"
- Snackbars are receipts, not celebrations: "Notes saved", "Added to grocery — checked-off items skipped"

**Counts & numbers.** Middot joins ("25 min · Serves 4", "9 items · from 3
planned recipes"); mono for meters ("600 / 600") and file paths. Show the
recipe's raw strings verbatim — never reformat "4–6 servings". Editor fields
render the words ("servings", "min") as controls so raw always matches what
the user saw. Comma decimals accepted ("1,5" hr — Norwegian keyboards).

**Emoji.** One surface only: pantry **category chip labels** ("🥦 Produce 12")
— they render as text via the system emoji font; custom tags are name-only.
Nowhere else; Material Symbols do all icon work. The review success bar
"Recipe rescued ✓" is a check glyph, not emoji.

**Suggest-and-confirm, never silent**: everywhere AI guesses, the UI flags
and asks ("Same thing? 2 lemons + 4 lemons → Merge · 6 lemons / Keep apart";
flagged lines get a "confirm" chip). No silent automation, ever.

## VISUAL FOUNDATIONS

**Color.** Moody Blue M3 (seed `#3F51B5`): primary `#24389C` (dark lavender
`#BAC3FF`), secondary `#4D5A9C`, and a magenta-pink tertiary **reserved for
exactly two moments** — the paywall ONE-TIME badge and the favorite heart.
Semantic colors: ONLY `success #22C55E` and `warning #F59E0B` exist (no
`info`), identical in both themes. **Contrast rule:** they're ~2:1 on light
surfaces — never raw text. Fill @12–14%, border @55–70% 1.5px, text blended
toward on-surface (`--success-text` / `--warning-text`); raw color only as a
small icon beside words saying the same thing. Failed state = the
needs-review shape in error; dimmed/skipped = 60% opacity.
**`primaryContainer` is a dark fill with a light on-color** (it exists to be
the FAB gradient's dark end) — reach for `secondaryContainer` for tonal fills.

**Two themes.** Light "Stitch Slate": warm cream scaffold `#FAF8F0` under
pure-white cards — that warm/cool contrast is the light theme's signature.
Dark "Midnight": deep navy `#0F1117`, never black; depth via the
surface-container ladder, not shadow. Toggle with `data-theme="dark"`.

**Type.** Plus Jakarta Sans (display/headline/title ≥15px, tight −0.01 to
−0.02em) + Inter (body/labels/titles ≤13.5px). Wordmark PJS w800 23px
primary. Cook-mode step text 27px, lh 1.4, never below 24. Section eyebrows
11px w600 +0.9px UPPERCASE — the only caps. Quantities bold inside body lines
("**400 g** spaghetti"). display-lg (48) and headline-lg (32) are defined but
unused. The Flutter theme sets NO line heights (Material defaults; 1.4–1.5
appears inline on a few screens) — treat body line-height as an open item.
Fonts are **bundled TTFs** (`assets/fonts/`), never runtime-fetched.

**Spacing.** 4px grid; 20px screen margins; 12px grid gutter and card gaps
(11–12); card padding 12 (default) to 16; eyebrow → card gap 12; lists clear
the floating bar by ~110px. Hit targets ≥44 (filled buttons 48, outlined 44,
cook-mode zones 60).

**Shape.** In practice the app is overwhelmingly **pill and 12**: radius 12
is the workhorse (row cards, grid tiles, notes, snackbars), full stadium the
other (search, chips, meta pills, segmented, buttons, FAB, nav pill). 8 for
small inputs/thumbnails; 16 feature cards + dialogs; 22 icon squircles; 24
sheet tops. Anything else is a smell.

**Cards.** White (surface-container-lowest), 1px hairline (outline-variant
@50%), radius 12, 12 padding, blue-tinted `0 4px 10px rgba(36,56,156,.06)`.
Selected = 1.5px primary border + Moody Blue glow replacing the shadow.
Row separators: outline-variant @35%.

**Glass.** The floating nav pill (blur 20) and hero overlay circles/pills
(blur 12) — translucent fill (white 55% light / black 35% dark) + hairline.
Content scrolls under the bar (`extendBody`).

**Gradients.** The 52px FAB (135° primary-container → primary + glow) — never
reused elsewhere. And the six **recipe cover gradients** (indigo, slate blue,
plum, terracotta, teal, olive — `--cover-*`): a coverless recipe gets a 135°
pair chosen by a stable title hash, watermarked with the LogoMark at 22%
white. **Screenshots are never promoted to covers** — originals stay one tap
behind the hero's provenance flip.

**Backgrounds & imagery.** Flat token surfaces. User screenshots appear only
as originals/import thumbs; missing ones show the 45° **striped placeholder**
("your screenshot"). Never stock food photography.

**Motion.** 150/300/500ms. Standard `cubic-bezier(0.2,0,0,1)`, entering
`(0.05,0.7,0.1,1)`, leaving `(0.3,0,0.8,0.15)` — no bouncy curves. Hover:
tint or 2px lift; press: ripple/scale ~0.98. (Known gap: the app doesn't yet
check the system reduced-motion setting.)

## ICONOGRAPHY

**One glyph system: Material Symbols Rounded** (Flutter `Icons.*_rounded`),
loaded from Google's CDN in `tokens/fonts.css`, wrapped by `Icon`. Filled
axis = active/selected — never a different glyph. Never hand-roll SVG icons,
never emoji-as-icon.

**The logo is real and drawn**: `LogoMark` (components/brand/) transcribes
the app's painter 1:1 — open book + two steam wisps, one flat color, spine
knocked out so it sits on any background. It is the app icon, the Cookbook
tab icon (book only ≤24px — the wisps mush below that), and the cover
watermark. Use the component; never redraw or approximate it. Lockup =
mark + "MyReciBook" PJS w800 primary.

Core glyphs: `menu_book`, `checklist` (Grocery), `download` (Queue),
`settings`, `add` (FAB), `search`, `photo_library`, `photo_camera`, `edit`,
`schedule`, `restaurant`, `favorite`, `timer`, `play_arrow`, `swap_horiz`
(provenance flip), `check_circle`, `smartphone`, `add_to_drive`, `cloud`,
`hourglass_top`, `push_pin`, `ios_share`, `event_repeat`, `delete`,
`arrow_back/forward`, `chevron_right`, `close`, `check`, `kitchen` (product
tile), `add_a_photo` (cover slot), `remove`/`add` (stepper).

## Components (`window.MyReciBookDesignSystem_4222aa`)

The inventory is exactly what the as-built spec + `skin.dart` + `widgets/`
define — nothing extra:

- **brand/** — LogoMark
- **forms/** — Button, SearchBar, FilterChip (cookbook filters,
  secondary-container selected), CategoryChipRow (pantry/Add-food, primary
  selected), SegmentedControl
- **editor/** — ServingsStepper, DurationField, CoverPickerField
- **surfaces/** — TokenCard, DashedInfoCard, GlassCircle, GlassPill
- **data-display/** — SectionLabel, MetaChip, StatusPill, IngredientRow
  (+ `qtyBold`), RecipeCard, RecipeCover (+ `COVER_GRADIENTS`, `coverSlot`),
  ProductRow, StripedPlaceholder
- **navigation/** — GlassNavBar (Cookbook · Grocery · [FAB] · slot 3 ·
  Settings; slot 3 is feature-flagged: Food / Pantry / Unlock / Queue),
  GradientFab, AppBackButton
- **feedback/** — ConfirmDialog (THE destructive confirm — reuse verbatim),
  Snackbar
- **icon/** — Icon *(intentional addition: thin Material Symbols wrapper
  mirroring the app's single glyph system)*

Screen-level patterns documented but deliberately not componentized:
ProductPickerSheet (composes SectionLabel + search + CategoryChipRow +
ProductRow in a drag sheet) and OriginalsViewer (full-screen black pinch-zoom
pager over source screenshots, "Original · N" title).

## Rules when adding (from the as-built spec)

- Any new color must map to an existing role; no one-off hexes.
- `secondaryContainer`, not `primaryContainer`, for tonal fills.
- `success`/`warning` are fills and borders, not text colors.
- Tertiary stays reserved (heart + ONE-TIME badge).
- Radius: pill or 12 unless you have a specific reason.
- Destructive confirms reuse ConfirmDialog; no new shapes.
- Icons are rounded Material Symbols with the fill axis for selected.

## Index

- `styles.css` — global entry (@import manifest only)
- `tokens/` — colors · typography · spacing · elevation · fonts · base
- `components/<group>/` — primitives above (`.jsx` + `.d.ts` + `.prompt.md` + demo card each)
- `guidelines/` — foundation specimen cards + `DESIGN-as-built.md` (the reviewed spec, incl. Known gaps)
- `assets/fonts/` — bundled Inter + Plus Jakarta Sans TTFs (+ OFL licenses)
- `ui_kits/android_app/` — *(planned)* interactive screen recreations
- `SKILL.md` — Agent-Skills–compatible entry point
- `github.md` — source-repo association for one-click sync

## Caveats

- **UI kit not yet built** — the screen inventory and every value needed are
  in `DESIGN-as-built.md` and the mounted `ui/` codebase.
- $24.99 / 600 rescues/yr are **working numbers** — placeholders in mocks too.
- **Known gaps** (drift the app ships with — don't design against them):
  no `info` color, no third elevation step, glass blur 12/20 (24 unused),
  reduced-motion unchecked, six unrounded icon call sites, outlined buttons
  44 vs filled 48, body line heights unset, dialogs 16 (not 24).
