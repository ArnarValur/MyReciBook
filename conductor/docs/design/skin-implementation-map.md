# Skin implementation map — session 2026-08-06 (late)

*What was actually built against the hi-fi spec, where it lives, and every
deviation with its reason. Spec: [handoff.md](handoff.md) + catches in
[review-notes.md](review-notes.md). Landed in commit `61119e1`.*

## Where things live

| File | Carries |
|---|---|
| `app/lib/ui/theme.dart` | DittoDatto tokens → Flutter. `RbColors` (full M3 light "Stitch Slate" / dark "Midnight" schemes, cream scaffold `#FAF8F0` / navy `#0F1117`, theme-stable success/warning), `RbTokens` ThemeExtension (blue-tinted card/modal shadows, primary glow, FAB glow, hairline @50%, separator @35%, glass fill/border — dark variants lean on tint not shadow), text theme (Plus Jakarta Sans display/headline/title, Inter body/label, tracked 11sp section-label style), component themes (stadium filled/outlined buttons 48dp, sheet radius 24 top, floating snackbars). |
| `app/lib/ui/widgets/skin.dart` | Shared primitives: `SectionLabel` (INGREDIENTS · 8), `TokenCard` (hairline + shadow; `selected` = 1.5dp primary + glow), `MetaChip`, `StatusPill` (quiet storage badge), `GlassCircle`/`GlassPill` (BackdropFilter 12), `GradientFab` (52dp, 135° primaryContainer→primary, glow — wraps a real `FloatingActionButton` so tests keep `find.byType`), `StripedPlaceholder` (the mockups' diagonal stripes, custom painter), `CoverImage` (Image.file → stripes fallback), `qtyBoldSpan` (bold leading "400 g" heuristic over `raw`, plain fallback), `OriginalsViewer` (full-screen pinch-zoom PageView — the provenance affordance shared by review + detail). |
| `app/lib/ui/import_sheet.dart` | 3a as a chooser sheet: grabber, "Add to your book", screenshots tile → system picker, hairline divider, "Snap a page" camera row (hidden when no camera injected — widget-test seam). Returns `ImportSource?`. |
| `app/lib/ui/recipe_list_screen.dart` | 3d + 4b: wordmark lockup (long-press = debug dev gallery), "On this phone" pill, pill search (live title filter), edge-bleeding filter chips All/Favorites/Quick(≤30 min)/Sweet(tag match), 2-col `SliverGrid` cards (106dp covers = screenshot-1 `BoxFit.cover`), skipped-files footer, empty state 4b, `GradientFab` at `centerFloat`. |
| `app/lib/ui/import_review_screen.dart` | 3c + 4c on the unchanged D5/D6 flow: "Recipe rescued ✓" bar + Retry, source-thumb row → `OriginalsViewer`, editable title card (warning border when flagged), servings/time chips, D4 no-steps card + add-screenshot, ingredient/step rows as borderless always-editable TextFields with hairline separators — flagged rows get warning@12% tint + `confirm` chip (tap or edit clears the flag, UI-state only), "Save to cookbook" CTA. Failure = 4c layout with error-typed titles. |
| `app/lib/ui/recipe_detail_screen.dart` | 3e: 210dp hero (cover ⇄ original `contain` flip via glass pill; tap → viewer), glass back/favorite/delete, title 23sp, time + servings chips, checkbox ingredient rows (`qtyBoldSpan`, strikethrough on check — ephemeral kitchen state), numbered steps (step 1 emphasized), notes card (D6 post-save edit), "Start cooking". Favorite persists via `copyWith(favorite:)` through the normal save path. |
| `app/lib/ui/cook_mode_screen.dart` | 3f: segment progress, "Step x of y · title", 27sp centered step text, timer parsed from step text (first "N min/hour" → in-screen countdown + haptic), 60dp back/Next whole-zone targets, wakelock (best-effort, guarded) with the caption shown only when actually held. |
| `app/lib/ui/postalpha/` | `dev_gallery.dart` (debug-only door, long-press wordmark) + `preview_screens.dart`: 3b batch queue, 3g paywall, 3h storage, 4a grocery (incl. the future glass NavBar shell as `_GlassNavBarPreview`), 4d cap — mockup demo data verbatim, engine-needing buttons explain themselves via snackbar. `kTopUpEnabled = false` product flag guards the top-up button (+1200/$5, decided 2026-08-30). |
| `app/google_fonts/` | Bundled Plus Jakarta Sans (400/600/700/800) + Inter (400/500/600/700) + both OFL licenses (registered in `main()` via `LicenseRegistry`). |
| `app/test/flutter_test_config.dart` | `GoogleFonts.config.allowRuntimeFetching = false` for every test. |

Engine touchpoints (deliberate, minimal): `Recipe.favorite` (schema §below) ·
`RecipeStore.resolveImage` + `LibraryModel.coverFor/imageFor` (covers/heroes
resolve `images/…` refs; §7 confinement preserved — unsafe refs → null →
striped placeholder) · `main.dart` themes + camera picker + font licenses.

## Schema change (T1 D1 amendment, agreed in review-notes)

`favorite: bool` — user-owned, lives in the user's file. **Emitted only when
true**, read with `?? false`: pre-amendment files round-trip byte-identical
(pinned by the existing round-trip suite), favorited files stay stable too.

## Deviations from the hi-fi — each with its why

1. **3c delete-screenshot toggle: omitted entirely.** Review note 1 demanded
   default OFF; beyond that, the engine cannot delete gallery originals yet
   (MediaStore delete + system confirm). A dead toggle is worse than none.
   Ships with the camera-roll cleanup-nudge engine (parked).
2. **3a inline gallery grid → system photo picker.** The mockup's in-sheet
   grid needs `READ_MEDIA_IMAGES` + a gallery dependency; the system picker
   needs no permission and multi-selects fine. Revisit with the batch track.
3. **3a segmented "one recipe / N separate": absent.** Batch is post-alpha
   (D5). Multi-select = one recipe (the single-recipe path). Sheet copy says
   so honestly.
4. **3a link input row: absent.** D9 made the link door post-alpha; showing a
   dead input promises a missing feature. Same reason the 4b empty state drops
   the "or paste a link" caption for now.
5. **3d bottom NavBar: not in the alpha shell.** Review notes: "minus
   Grocery/Plan tabs" — a one-tab glass bar looks broken, so the alpha ships
   FAB-only at `centerFloat` (same position the FAB keeps when the bar
   arrives). The full 2+2 glass bar exists as `_GlassNavBarPreview` (4a).
6. **3e servings stepper → static chip.** Live rescale is the serving-rescale
   engine (parked); a stepper that changes nothing would lie. Chip shows
   `servings.raw`.
7. **3e "Grocery" footer button: omitted** (engine post-alpha); "Start
   cooking" kept full-width. Delete moved into the hero as a third glass
   circle — not in the mockup, but the bare flow's delete must survive
   (skins never remove flows).
8. **3f "FOR THIS STEP" chips: omitted.** Schema has no step↔ingredient
   mapping; inventing one client-side would guess. Needs a schema/extraction
   decision — flag for the next grill.
9. **3f timer: in-screen countdown only** (haptic on zero; no notification,
   no background survival). Honest v0 of the mockup's affordance.
10. **4c failure titles are error-typed.** "That one kept its secrets" is
    reserved for genuine no-recipe reads; offline → "You're offline",
    rate-limit → "Give it a minute" — calm layout unchanged, reassurance line
    ("gallery untouched, nothing deleted") always present, cap line omitted
    (no cap in alpha).
11. **Fonts bundled, not runtime-fetched** (technical rule 8): google_fonts
    rethrows fetch failures into the test zone, and a kitchen app shouldn't
    need network for its own type. Cost: ~2.2 MB APK.
12. **Review flagged-line "confirm" is UI state only** — it normalizes the row
    but writes nothing to the file (the schema has no per-line confirmed
    field). Acceptable: saving IS the confirmation in D6's model.

## Test contract changes (all deliberate)

- New `startImport` helper: FAB → sheet → `Key('import-screenshots-tile')`.
- Copy-driven finders updated: `Save to cookbook` · `Recipe rescued` ·
  `Try again` · `You're offline` · empty-state copy · grid `find.text` instead
  of `ListTile` · `Icons.delete_rounded`.
- Notes test drags the detail ListView −600 first — the notes card lives below
  the fold of a lazy list now.
- `settle` rounds 20 → 32: font-asset loads and cover decodes consume real-IO
  rounds (rule 8 rider). Snackbar assertions use a short settle (6 rounds) —
  a full one outlives the 4s snackbar.
- Stable keys added for future tests: `import-screenshots-tile`,
  `import-camera-tile`, `cookbook-search`, `confirm-ingredient-<i>`,
  `favorite-button`; `notes-field` kept.

## Verification evidence

- `flutter analyze`: clean. `flutter test`: **77/77 green** (same count as the
  engine baseline — no coverage lost in the reskin).
- Debug APK (`--dart-define-from-file=dev.env`) built, installed, launched on
  the S21 (R5CR61FGVPN); screencap verified the dark "Midnight" render:
  wordmark, pill, search, chips, real recipe card with its actual screenshot
  as cover, gradient FAB.

## Post-alpha wiring points

| Preview | Waits for | Wire-in |
|---|---|---|
| 3b batch queue | `ExtractionJob` queue engine | replaces the single-import spinner phase; cookbook header chip while running |
| 3g paywall | Play Billing + `Entitlement` (5 free rescues) | pushed route before 6th rescue; price/cap numbers still placeholders |
| 3h storage | SAF store + Drive/Dropbox connectors (arch §8) | becomes real under a Settings tab; "This phone" already true today |
| 4a grocery | grocery engine + serving-rescale + meal plan | promotes `_GlassNavBarPreview` into the real shell (2+2 tabs) |
| 4d cap | proxy per-install counter (D7) | `kTopUpEnabled` stays false until the consumable IAP exists; pack decided 2026-08-30: +1200 rescues, $5 flat, never expires (ai-cap-mechanics.md §5) |
| manual entry | "Type it in by hand" flow (also 4c's second button) | unlimited by promise — never metered |
