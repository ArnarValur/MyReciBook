# Handoff: MyReciBook — Android MVP screens

*Imported 2026-08-06 from the Claude Design project "MyReciBook Flutter mockups"
(`design_handoff_myrecibook/README.md`). The mockup HTML + token CSS live in
`docs/MyReciBook Flutter mockups.zip`. Adopted with the four catches in
[review-notes.md](review-notes.md); skin implemented in `app/lib/ui/` 2026-08-06.*

## Overview
MyReciBook is an Android-first (Flutter/Dart) recipe app. Core thesis: **screenshot-first AI import + user-owned recipe files + pay-once pricing**, marketed as "rescue the recipes buried in your camera roll." This package covers the 12 designed screens/states of the MVP: import, extraction review, cookbook, recipe detail, cook mode, grocery list, paywall, storage setup, and edge states.

## About the Design Files
`MyReciBook Mockups.dc.html` is a **design reference created in HTML** — a prototype showing intended look and behavior, not production code. The task is to **recreate these designs in Flutter** using Material 3 (`ThemeData` + standard widgets), matching the tokens below. The file contains 4 iteration "turns": **turn 3 (ids 3a–3h) and turn 4 (4a–4d) are the hi-fi spec; turns 1–2 are superseded wireframes** kept for rationale.

## Fidelity
**High-fidelity** for turns 3–4: colors, type, spacing, radii, and copy are final intent — recreate faithfully with the Flutter theme below. Striped areas labeled `your screenshot` are image placeholders for user content, never shipped artwork.

## Target & Conventions
- 360dp-wide reference frame (Galaxy S21). All px values below = dp 1:1.
- Material 3, **Material Symbols Rounded** icons only (`Icons.*_rounded`). Filled axis for active/selected states. Never emoji-as-icon, never custom SVG icons.
- Both themes ship: light "Stitch Slate" (default) and dark "Midnight" (deep navy, never black). Every screen is designed in both.
- Copy: English, playful, sentence case everywhere (buttons included). ALL-CAPS only for tiny tracked section labels (`INGREDIENTS · 8`). Use the exact strings in the mockups; they are drafted final copy.
- Hit targets ≥ 44dp. Cook-mode text ≥ 24sp.

## Design Tokens → Flutter

### Color (Material 3, seed `#3F51B5` "Moody Blue")
Light scheme:
- primary `#24389C`, onPrimary `#FFFFFF`, primaryContainer `#3F51B5`, onPrimaryContainer `#CACFFF`
- secondary `#4D5A9C`, secondaryContainer `#ABB7FF`, onSecondaryContainer `#394687`
- tertiary `#88003B`, tertiaryContainer `#B40050`, onTertiaryContainer `#FFC3CE` — **reserved for rare CTA moments** (only: the ONE-TIME badge on the paywall, the favorite heart)
- error `#BA1A1A`; status: success `#22C55E`, warning `#F59E0B`, info `#3B82F6`
- surface `#F9F9FC`, scaffold `#FAF8F0` (warm cream), surfaceContainerLowest `#FFFFFF` (cards), surfaceContainerLow `#F3F3F6`, surfaceContainer `#EEEEF0`, surfaceContainerHigh `#E8E8EA` (chips, icon circles), surfaceContainerHighest `#E2E2E5`
- onSurface `#1A1C1E`, onSurfaceVariant `#454652`, outline `#757684`, outlineVariant `#C5C5D4` (hairlines at ~50% alpha)

Dark scheme: primary `#BAC3FF`, onPrimary `#071A86`, primaryContainer `#293CA0`; scaffold `#0F1117`, surfaceContainerLowest `#0A0C11`, surfaceContainer `#161922`, surfaceContainerHigh `#1C1F2B`, surfaceContainerHighest `#262A36`, onSurface `#E4E2E6`, outlineVariant `#454652`. Elevation in dark = surface tinting, shadows softened.

### Typography (bundled Google fonts)
- **Plus Jakarta Sans** — display/headline/titles. Screen titles 22–23sp w700 (−0.01em); hero headlines 26–29sp w700 (−0.02em); wordmark "MyReciBook" 23sp w800 primary; card titles 13.5–15sp w600–700 (Inter ok ≤15sp).
- **Inter** — body/labels. Body 13.5–14sp w400–500; captions 12–12.5sp onSurfaceVariant; section labels 11sp w600, letter-spacing 0.9px, uppercase; mono moments (paths, counters) 11.5sp.

### Shape
radius: 8 buttons/small inputs · 12 list cards/inputs · 16 large cards/dialogs · 22 icon-squircles · 24 bottom sheets (top) · full/stadium for pills: search bar, chips, segmented control, primary CTAs, FAB.

### Spacing
4px grid: 4/8/12/16/24/32. Screen padding 20 horizontal. Card internal padding 12–16. Gap between stacked cards 11–12. Section label → card gap 12.

### Elevation & effects
- Card shadow (light): `0 4px 10px rgba(36,56,156,0.06)`; modal `0 8px 20px rgba(36,56,156,0.12)` — blue-tinted, subtle.
- Focus/selected glow: `0 0 12px 2px rgba(63,81,181,0.15)` (selected storage card, merge prompt).
- Glass (nav, hero overlays): translucent fill (`rgba(255,255,255,0.55)` light / `rgba(0,0,0,0.35)` dark) + 20–24 blur + 1px hairline. Flutter: `BackdropFilter`.
- Motion: 150/300/500ms, easing `cubic-bezier(0.2,0,0,1)`. No bouncy curves. Respect reduced-motion.

## App shell
Bottom glass NavBar, floating (`extendBody: true`): 56dp pill, 4 tabs split 2+2 around a center FAB — **Cookbook** (menu_book) · **Grocery** (checklist) · [FAB] · **Plan** (calendar_month) · **Settings** (settings). FAB: 52dp, gradient `135° primaryContainer → primary`, white add, glow `0 8px 16px 2px rgba(63,81,181,0.45)`. FAB opens the Import sheet. *(Alpha ships FAB-only — Grocery/Plan are post-alpha, review-notes.)*

## Screens
1. **Import sheet (3a)** — modal sheet over 45% scrim, radius 24, grabber 36×4. "Add to your book". `FROM YOUR SCREENSHOTS` gallery grid (system picker pre-filtered to screenshots) · segmented "One recipe · N shots / N separate recipes" (batch = post-alpha) · link pill (post-alpha, D9 blogs-only) · "Snap a page" camera row ("handwriting welcome") · stadium CTA "Rescue as one recipe".
2. **Batch queue (3b)** — post-alpha. Non-blocking; done/flagged/extracting/waiting cards; only flagged demand attention; "Not a recipe? We skip it and say so."
3. **Extraction review (3c)** — the core moment. "Recipe rescued ✓" + Retry · source-thumb row (tap = compare) · editable title card · meta chips · `INGREDIENTS · N` card with **flagged rows** (warning@12% bg, confirm chip — suggest-and-confirm, never silent §6.3) · `STEPS · N` · ~~delete-screenshot toggle~~ (OFF by default per review note 1; omitted until engine support) · "Save to cookbook".
4. **Cookbook home (3d, empty 4b)** — wordmark lockup + quiet storage pill ("Synced" / "On this phone", both quiet — review note 3) · pill search · filter chips (All/Favorites/Quick/Sweet) · 2-col grid, 108dp covers = original screenshot BoxFit.cover (tier-1 zero-effort covers) · empty state sells the batch rescue.
5. **Recipe detail (3e)** — 210dp hero (cover ⇄ original glass flip = provenance) · glass back/favorite (heart = tertiary moment, schema `favorite` bool) · title 23 w700 · time chip + servings (stepper post-alpha with rescale engine) · checkbox ingredient rows, qty bold · numbered steps, step 1 emphasized · "Start cooking".
6. **Cook mode (3f)** — wakelock, segment progress, step text PJS 27 w600 centered, timer chip parsed from step text, 60dp back/Next zones, "Screen stays awake while you cook".
7. **Paywall (3g)** — post-alpha. "Pay once. Cook forever." · $25 + ONE-TIME tertiary badge · **cap stated in writing** (constraint 2) · "Why not a subscription?" expander · Restore purchase. $25 and 600/yr are working numbers.
8. **Storage setup (3h)** — post-alpha connectors. This phone (default, selected) · Drive (`drive.file` app-folder) · Dropbox · on-disk JSON preview · "If MyReciBook vanished tomorrow, your recipes wouldn't."
9. **Grocery list (4a)** — post-alpha, the retention layer (§6.3): sync receipt banner · merge prompt (suggest-and-confirm) · remembered aisles ("your aisle" pin) · quiet staples.
10. **Extraction failed (4c)** — "That one kept its secrets" · three reassurances: gallery untouched, nothing deleted, cap unspent · Try again / Type it in by hand (manual entry post-alpha).
11. **Cap reached (4d)** — post-alpha. Kept-promise framing · 1200/1200 meter · hand-entry always unlimited · **top-up decided 2026-08-30: +1200 rescues, $5 flat, never expires** — still behind `kTopUpEnabled` until the consumable IAP exists (ai-cap-mechanics.md §5).

## Interactions (cross-screen)
- Import entry points: FAB → sheet; Android share sheet → same pipeline (T3 next step).
- Extraction contract: per-line confidence; below threshold → flagged treatment; clean batch items auto-save (post-alpha).
- Provenance: original screenshot stored with the recipe; reachable from review, detail hero flip, compare view. Source-deletion toggle never touches the stored copy.
- Scaling: servings stepper = single source of truth for detail, cook chips, grocery (post-alpha engine).
- Navigation: nav persists on tab screens; import/review/detail/cook/paywall/storage are pushed routes/sheets. Max one sheet deep.
- Loading: per-item determinate bars, never a full-screen blocking spinner (alpha single-import keeps the D5 spinner→failed→retry flow until the batch queue lands).

## State (suggested)
`RecipeFile` (one JSON per recipe, user storage), `ExtractionJob` (queued→extracting→needsReview|saved|failed|skippedNotARecipe), `GroceryList` derived live from `MealPlan`, `MergeSuggestion`, per-store `AisleMapping`, `staples`, `Entitlement` (freeRescuesUsed 0–5, purchased, capUsed/capTotal, topUpBalance), `StorageBackend` (local | drive | dropbox; last-write-wins + conflicted-copy §6.5).

## Product constraints that must survive implementation
1. Suggest-and-confirm everywhere AI guesses — no silent automation.
2. One JSON file per recipe in user-owned storage; no backend beyond the stateless proxy (+ cap counter).
3. Fair-use cap stated at purchase, enforced transparently; hand-entry unlimited; failed extractions don't count.
4. Pay-once, hard paywall; never "unlimited forever".
5. Link import is a degradable bonus behind a kill-switch flag.
