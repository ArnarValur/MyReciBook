# tags

**Goal:** the user invents their own recipe tags in Settings — name, icon, colour —
tags recipes with them, and filters the cookbook by them. Favorites stays as it is,
a built-in that no tag can replace or delete.

**Division:** Arnar owns icons, colours and the picker's look — his standing rule.
Agent owns the store, the model, the filter seam and the curated icon catalog.
Ships behind `kRecipeTagsEnabled`, which exists and is already off for exactly this.

**REWORKED 2026-08-28 at 0.17.5+29** to Arnar's shape after a day on the phone:
cookbook = folded tag shelf on CollapsibleShelf (untagged flat above, sections
alphabetical, chips row All + Favorites only, folds in cookbookOpenSections) ·
editor = full page, no drawer, no search bar (typed-emoji hatch parked with it),
icon grid tints to the chosen colour, reached from Settings AND the recipe
picker (showTagEditor returns the saved name) · badges list-view only · Quick
chip deleted · glyphs wear their colour everywhere, heart is tertiary
everywhere. Regressions pinned: tag_editor_screen_test (a Center in
bottomNavigationBar once shipped a blank editor), recipe_store_scan_test
(tags.json is never a "couldn't be read" count).

**BUILT 2026-08-27 at 0.13.0+14.** Every ❓ was answered by Arnar that day:
colour in v1 (yes, 8 tints) · emoji escape hatch (yes) · built-ins are
Favorites + Quick, Sweet deleted · delete strips the name from the recipe
files. The three the plan proposed defaults for were taken as proposed:
single-select filter, no tag cap, filter does not survive a restart.

## What already exists — the reason this is small
- `Recipe.tags: List<String>` is in the file format and in recipe.schema.json.
  Absent-unless-set, so tagging a recipe never breaks a byte-identical round-trip.
- `kRecipeTagsEnabled` (features.dart) hides the Quick/Sweet chips "until a
  tagging design exists". This is that design; the flag is the switch.
- `recipe_list_screen._filterRow` already draws icon+label chips with the
  selected/unselected skin. It takes a list; today the list is hard-coded.
- `pantry_tab` line 387 already has a "+ Category" bottom sheet — the tag
  picker on recipe detail is the same sheet with a different source list.
- ~~Nothing writes recipe tags today.~~ WRONG, found 2026-08-27 by Arnar on a
  real library: link_extractor._tags maps recipeCategory + recipeCuisine +
  keywords into `tags`, up to 8 per recipe. Screenshot extraction emits none.
  So a rescued recipe arrives pre-tagged with the site's own vocabulary, and
  the import review now shows those tags and lets them be edited before save.

## Where the two halves live
- **Membership → the recipe file.** `"tags": ["Weeknight"]` in `<id>.json`.
  User-owned, syncs, survives reinstall, readable by a human. No schema change.
- **Decoration → `tags.json` at the root of the user's folder.** name, icon,
  colour, label-shown, order. Syncs beside the recipes; one `_ownedName` case in
  sync_engine (the pantry/ and diary/ precedent), one store, one model.
- **The recipe files win.** `tags.json` missing or corrupt → the app still lists
  every tag string it finds across the library and draws it plain, no icon.
  A tag can lose its outfit; it can never be lost. Arch §7 stance, applied.

## The tag record — two fields, not three modes
```json
{ "name": "Weeknight", "icon": "bolt", "color": "amber", "showLabel": true }
```
- icon + showLabel → pill: ⚡ Weeknight
- icon, no showLabel → **circle**, not a pill. Icon only.
- no icon → label only; showLabel is forced true, so "blank chip" is unrepresentable.
- Icon-only is the only tag form that fits on a grid cover card next to the
  heart without eating the title. That is what earns it, not just charm.

## Identity — key is the name
- Renaming a tag rewrites the recipe files that carry it. N is small, writes are
  atomic, and the alternative (`"tags": ["t_8f2a"]`) makes the user's own file
  unreadable — which the bet forbids. Two tags cannot share a name; they'd be
  the same tag.
- A tag string in a file with no `tags.json` entry is legal and renders plain.
  Hand-edited files and foreign folders just work.

## Colour — beyond what was asked, propose anyway
- 8 tints off the M3 scheme, default `primary`. A row of icon-only chips with no
  colour is a wall of navy and unreadable at a glance; colour is what makes the
  icon-only form work.
- Same table should later serve the parked pantry category icons/colours.
- ❓ Arnar: colour in v1, or ship monochrome and add it after seeing it?

## The icon collection — Material Symbols Rounded, curated, keyed
- Brand law (design skill): Material Symbols Rounded only. No new font package,
  no new dependency, no asset weight. The collection is a curation of what is
  already in the binary.
- `domain/tag_icons.dart` — pure Dart. The stable string keys + search terms +
  group names. This is what a user file stores.
- `ui/icons/food_icons.dart` — `const Map<String, IconData>` binding each key to
  an `Icons.*_rounded` constant. Flutter side.
- Keys, never codepoints, for three reasons:
  1. `"icon": "pizza"` stays readable and portable; `59567` does not.
  2. `--tree-shake-icons` is ON in release. An icon reached only through a
     runtime-built `IconData(codepoint)` gets stripped and renders as a box —
     in the release APK only, never in debug. A const map keeps every icon
     referenced, so the shake keeps them. Real trap, closed by design.
  3. An unknown key falls back to a neutral default instead of crashing.
- Groups: Dishes · Ingredients · Kitchen & tools · Occasions · Dietary · Time.
- Honest size: Material is good on dishes, meals, drinks and kitchen gear, thin
  on named ingredients — no avocado, no broccoli. Expect 60–90 icons, not 300.
- **Emoji escape hatch:** the icon field accepts either a catalog key or a
  literal emoji the user types. `^[a-z_]+$` disambiguates. Android ships Noto
  Color Emoji, `category_chips.dart` already relies on it, and it costs nothing.
  Brand-clean defaults, unlimited vocabulary for anyone who wants 🥑.
  ❓ Arnar: emoji in, or Material-only and keep the row monochrome-tidy?

## Build order
- [x] `domain/tag_icons.dart` + `ui/icons/food_icons.dart` — catalog first,
      nothing depends on the rest of the track. Reusable immediately.
- [x] `domain/recipe_tag.dart` — the record, JSON in/out, name-key rules.
- [x] `data/tag_store.dart` — `tags.json`, atomic write, corrupt→empty (never crash).
- [x] `sync_engine._ownedName` — one case for `tags.json`.
- [x] `ui/tags_model.dart` — list, create, rename, recolour, reorder, delete.
- [x] Settings → Tags screen. Create/edit sheet: name field, icon picker with
      search, colour row, "show the label" switch, live chip preview.
- [x] Recipe detail: tag row under the title, `+ Tag` sheet (pantry's shape).
- [x] Cookbook `_filterRow`: user tags appended after the built-ins; flip
      `kRecipeTagsEnabled`.
- [x] Delete the `_isSweet` predicate — nothing ever earned it.

## Open questions — Arnar's calls
- ❓ **Quick stays or goes?** `_isQuick` (total ≤30 min) is computable and honest,
  unlike Sweet. Proposal: keep Favorites + Quick as the two built-ins, user tags
  follow. Alternative: built-ins are Favorites alone, everything else is earned.
- ❓ **Deleting a tag** — strip it from the recipe files too, or leave the strings
  and only drop the decoration? Proposal: strip. A filter for a tag nobody can
  see is a ghost. Costs a write pass over the recipes that carry it.
- ❓ **One filter at a time, or stacking?** Today's row is single-select and
  Favorites behaves that way. Proposal: single-select in v1; AND/OR needs a
  different affordance and can follow.
- ❓ **Tag limit.** A cap (say 20) keeps the filter row scrollable rather than
  endless. Proposal: no hard cap, but the row scrolls and Settings owns the order.
- ❓ **Filter persistence.** Proposal: no. A filter that survives a restart makes
  the cookbook look empty and broken. Session-only, like today.

## NOT done — the one deliberate omission
Every string this track added is an English literal, not a gen_l10n key
(Arnar 2026-08-27: "dont think about i18n now, just normal english version").
The i18n sweep picks them up with the rest of lib/ui. Files to revisit:
tags_screen · tag_editor_sheet · tag_chip · the Settings row · the recipe
detail sheet. Only English is offered today, so arb_parity_test stays green.

## i18n — landed on main 2026-08-22, after this plan was written
- Every string this track adds goes through gen_l10n, not a literal: the
  Settings→Tags screen, the picker, the built-in chip labels (All / Favorites /
  Quick). `arb_parity_test` fails the suite if a key is missing from a locale.
- User tag NAMES are user data. Never translated, never keyed, never touched.
- Icon catalog group names ("Dishes", "Kitchen & tools") and the picker's search
  terms are UI strings — they need keys, and search must match the localized
  term, not the English one.

## Added after the first pass — 0.14.0+17
- Tags an import ARRIVES with are shown in the review screen, each removable,
  with the shared picker to add more. Nothing lands in the cookbook untagged
  or over-tagged without the user having seen it.
- One picker sheet (`ui/tag_picker_sheet.dart`) serves both the recipe page
  and the review, so tagging reads the same before and after a save.
- A tag the library carries but tags.json does not can be deleted straight
  from Settings. Adopting it only to delete it was the long way round.

## Not in this track
- Auto-tagging from the extractor. Nothing earns a tag but the user's tap.
- Tag-driven meal planning, tag search syntax, tags on the grocery list.
