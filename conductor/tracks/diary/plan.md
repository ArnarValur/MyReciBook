# diary

**Goal:** MyFitnessPal's meal diary on MyReciBook's own foundations — log what you
ate into a day, from the pantry, from a recipe, or typed in, and see the day total
against a goal. This is the piece that makes pantry, scanner and recipes one app.

**Shipped 2026-08-28 at 0.18.2+33:** custom meal hours — Settings → Meals
renames, reorders, adds/removes, and sets an optional "from HH:mm" per meal
(meal_hours in settings.json; currentMealName in domain/diary.dart wraps
midnight so a night shift's windows hold; today's shelf dots the current meal;
renames still never rewrite past days) · pantry cold start —
SafBridge.readChildFiles batches the folder's JSONs into ONE channel call
(recipes too), AppShell warms the pantry post-frame, the tab shows a spinner
then a retry on a failed first scan, ensureLoaded shares one in-flight scan ·
scan row is 3/4 Scan + 1/4 "+" into the create screen with no barcode.
Deferred by Arnar: the day-rollover "day starts at" hour (a 02:00 meal still
lands on the calendar day). Index-file cache parked — batch read carries 1000+.
Both stores skip app-owned root files on scan (RecipeStore.appOwnedFiles,
tags.json) — any future app-owned file goes in THAT list or the pantry
adopts it as a product.

**Sanded 2026-08-28 at 0.17.5+29:** meal sections in the CollapsibleShelf card
(session-only folds, kcal on the header) · Trends drops all-zero micro rows
(diary_stats_test pins it) · label micros forced to grams in the prompt with
drop-ceilings in label_read (vitamin >1 g, mineral >5 g per 100 g — a raw µg
number once landed as 30.4 g of folate; Arnar re-reads that oats label).

**Division:** Arnar owns UI and design — no mockup turn ever drew a diary, so the
first diary screen is a design decision he makes, not one the agent assumes. Agent
owns the engine.

**No new backend.** One JSON per logged day in the user's own folder, beside
recipes and pantry.

## The MFP mechanics being copied, and how each maps here
- Day → named meals → entries. MFP: Breakfast/Lunch/Dinner/Snacks, renameable.
- An entry is a food + a serving + how many. MFP stores servings, not grams —
  "2 × 1 dl", not "70 g". Ours does the same; grams ride along when known.
- Serving options per food: the pack's portion, plus 100 g, plus a typed amount.
  Open Food Facts' `serving_quantity` fills the pack portion when it has one.
- Quick Add: calories with no food behind them.
- Recent / Frequent list in the picker, so the second week is three taps.
- Copy a meal to another date.
- Day total vs a goal — MFP's "Goal − Food = Remaining" line.
- Custom foods: type a name and its numbers. This is how fruit and veg with no
  barcode get in, and it is the top ask.

## Decided by the engine, on purpose
- **Entries snapshot their nutrition.** MFP re-resolves from a server it owns;
  our foods are files the user edits, rescans and deletes. A diary that rewrites
  last Tuesday because a product was corrected today is worthless. `ref` is kept
  for "edit" and "log again", never for arithmetic.
- **Per-serving is stored, not the row total.** Quantity edits are one multiply,
  no rounding drift.
- **Meal names are stored per day.** Renaming a meal tomorrow must not rewrite
  what yesterday said.
- **An empty day has no file.** Opening the app must not litter a year of empties.
- **A refresh never overwrites a serving the user typed.** It only fills an empty
  list.

## Built and on the branch
- [x] `domain/diary.dart` — day/meal/entry, totals, add/remove/update/move/copy,
      snapshot builders, date guard
- [x] `Serving` on Product + `servingOptions` (100 g always offered) — schema
      additive, pre-serving files gain no keys
- [x] `Nutriments.scaled` / `.plus` / `sumNutriments`
- [x] `data/diary_store.dart` — LocalDiaryStore, one file per day, recents walk
- [x] Open Food Facts `serving_size` + `serving_quantity` → the pack portion
- [x] 51 tests, whole suite 578 green serially
- [x] `SafDiaryStore` — diary lives at `<tree>/diary/`, beside recipes and pantry
- [x] Day screen: day walker, totals card, four meal sections, row edit sheet
      (change amount / move meal / remove) — `ui/diary/diary_tab.dart`
- [x] Nav slot 3 is "Food": Diary + Pantry behind a segmented control
      (Arnar 2026-08-19), behind `kDiaryEnabled`
- [x] Add food: pantry search · Recent · Scan · Create food · Quick add
- [x] Log sheet: portion chips + "Weigh it" + how many, live numbers, pinned CTA
- [x] Create a food by hand — the no-barcode door, saves a normal product file;
      doubles as the product edit screen (`ManualProductScreen(initial:)`)
- [x] Daily goal in Settings → Diary: kcal + macro grams, all optional
- [x] Gemini model → `gemini-3.5-flash-lite` for cost (Arnar 2026-08-19)
- [x] On the S21, release build with keys, 2026-08-19
- [x] 594 green serially
- [x] One ProductRow card for pantry list AND picker — photos in both
- [x] user_edited flag: hand-saves marked, bulk refresh skips them + confirms
      with counts; per-product OFF refresh on detail (may override, clears mark)
- [x] Edit door from the pantry detail page (closes that open item)
- [x] Product tags: 20 suggestions + custom on create/edit, filter pills on
      the shelf; open list in the file, schema-additive
- [x] 602 green serially, on the S21 2026-08-19
- [x] Diary sync case: diary/<date>.json in the layout, both sources + engine
- [x] Per-serving calculator (domain/recipe_nutrition.dart) + deterministic
      ingredient parse at compute time — link imports covered without rewrites
- [x] Log a recipe from Add food: per-serving snapshot, whole-recipe fallback,
      honest "estimated from N of M" basis line
- [x] Nutrition card on recipe detail, hidden until something is linked
- [x] Manual entry revamp v1: live parse + link pantry products while
      composing; recipes born with qty/unit/item/productRef
- [x] Model swap finished everywhere it bites (proxy allowlist!, spike, docs)
- [x] 637 green serially + proxy 10, on the S21 2026-08-19
- [x] Unified recipe editor 2026-08-20: one row-editor screen for New+Edit
      ("New Recipe"), edit pre-fills + saves in place + keeps screenshot
      pane, re-parse on line edit, ImportReviewScreen import-only
- [x] Inline unit select from linked product's base unit; "Fix the
      reading" popup removed
- [x] Linked rows render the product name inline (linkedIngredientLine),
      typed text preserved in the file — editor and detail
- [x] Servings stepper · min/hr duration · cover picker w/ camera
      (ui/widgets/editor_fields.dart); manual recipes store structured
      servings/time
- [x] Add food: Recent → recipes strip → pantry; search reaches recipes
- [x] 7-test e2e: links → picker kcal → snapshot entry; snapshot survives
      product edits (test/ui/recipe_diary_chain_test.dart)
- [x] Phase-1 work verified 666 green; post-rewrite suite NOT run

## Pantry categories — phased, one phase per session go (Arnar 2026-08-20)
Design: no Settings page; auto-tag is the engine, hand-tag on product edit
is only the correction path. `user_edited` tags are never overwritten.
- [x] **Phase 1 — auto-tag engine** (2026-08-20). 22 canonical categories
      in domain/product_categories.dart; four-tier match: category
      overrides (Berries/Chicken/Wine/Oils) → PNNS fine → PNNS broad →
      broad category taxonomy (Nordic products often have EMPTY
      food_groups_tags — live-verified on kjøttboller). Applied on scan
      and refreshAll; fill-only, user tags never touched. 50 green on
      touched files. Untagged renders as "Other" (phase 2, render-only).
- [ ] **Phase 2 — shelf UI.** Refresh button compressed to an icon+count
      on the "Pantry" title row. Freed space → horizontally scrolling chip
      row: All + categories-with-counts that exist in the pantry. Tap chip
      = filter to that category. "All" = grouped sections, alphabetical
      inside, sticky small headers. Untagged renders under "Other".
      NO icons/colours yet — Arnar owns that design and is researching it;
      build the chips/rows plain, colour lands as its own later pass.
- [x] **Phase 3 — picker drawer** (2026-08-20). Shared CategoryChipRow
      (ui/widgets/category_chips.dart) under the Add-food search; filter
      composes with search, counts stay whole-pantry, Recent/recipes
      untouched. Shelf swapped to the same widget. Emoji on canonical
      chips + shelf headers via categoryLabel — Android's system emoji
      IS Noto Color Emoji, zero assets (Arnar's icon call).
- [x] **Phase 4 — starter food packages** (2026-08-20, built; values
      UNVERIFIED). domain/starter_foods.dart: Vegetables 65 · Fruits &
      Berries 49 (doc's duplicate maracuja folded into Passion Fruit) ·
      Spices & Herbs 35, transcribed from docs/gemini-categories.md with
      Norwegian synonyms corrected. USDA carbs stored raw; toProduct
      subtracts fiber → files land EU-convention. Import door on the
      pantry tab → StarterFoodsScreen; existing foods skipped, never
      overwritten. Products gained optional `synonyms` (schema-additive);
      picker search matches them ("Paprika" finds Bell Pepper).
      OPEN before this ships in a release: USDA verification agent run
      over the table's values (Arnar owns the run; file is the one place
      to patch). Packages stay produce/spices only — bakery/butcher/deli
      rejected, those carry labels or barcodes (Arnar in the doc).

## Consolidation shipped 2026-08-20 (after phase 4)
- [x] ONE product picker (ui/widgets/product_picker_sheet.dart): search +
      synonyms + category chips; recipe detail + editor link sheets use
      it, both old ad-hoc drawers deleted.
- [x] Edit-screen tag pills seed from productCategories — the old
      productTagSuggestions list is gone; one category list everywhere.
- [x] Quick category pills on the product detail page; PantryModel.setTags
      saves tags without flipping userEdited.
- [ ] Three test files still target the deleted drawer: manual_entry,
      edit_recipe, recipe_detail_link. Rewrite against the shared sheet
      WHEN Arnar orders a test pass — one hung 9m40 on 2026-08-20.

## Design pass 2026-08-27 — shipped at 0.16.0+21
Built by four parallel agents from docs/MyReciBook Flutter diary-pantry-mockups.zip
(option ids are that file's own), then welded on main.
- 1a Diary tab and 1d scanner ratified as built — no work.
- 1b Pantry tab: starter foods is a leaf icon on the title row, chip bar and
  flat dump replaced by ui/widgets/collapsible_shelf.dart, search over name +
  brand + synonym, fold state persisted in settings.json.
- 1c Product page: overview and Edit unified into ui/pantry/product_page.dart.
  Debounced autosave, back flushes, no Save button. SIZE reuses the existing
  Product.quantity. A barcode-less rename is a FILE MOVE — held to the exit
  flush or typing spawns a file per keystroke.
- 2a/2b Add sheet: tabbed Pantry | Recipes, folded shelf inside the sheet,
  recipes browsed by recipe tag. Recipe→diary logging already existed; no
  engine was added. ui/diary/link_recipe_sheet.dart is the "start linking" door.
- 3a/3b Trends: domain/diary_stats.dart + ui/diary/trends_screen.dart. A year
  is one directory listing plus one read per logged day, cached per session.
  "kcal avg / logged day" everywhere — averaging over unlogged days would make
  a blank day a zero-calorie day.
- Known deviations from the drawings: shelf headers are 44dp not 34 (touch
  target); the vitamins card is hidden when the file carries no extras; a tag
  wearing a catalog icon shows its name only in a shelf header, because
  ShelfSection.label is a String.
- UNRESOLVED: Arnar reports multiple rough corners in these surfaces, not yet
  named. First job next session is naming them on the device.

## Product photos on every card — SETTLED and shipped (Arnar 2026-08-28)
- Arnar's call: photo WITH the provenance icon shrunk to a corner badge —
  identity and provenance both kept. Shipped 0.18.3+34: _EntryAvatar in
  diary_tab draws the product photo or recipe cover on diary lines, source
  icon badged in the corner; icon tile unchanged when there is no photo, a
  deleted source, or no pantry/library model (tests).
- Add sheet already carried photos (ProductRow) and covers (_RecipeRow);
  _RecentRow keeps its history glyph on purpose.

## Open — NEXT SESSION STARTS HERE
- [ ] Redeploy to the S21 (it runs the phase-1-3 build; starter foods and
      the picker consolidation are newer). Then Arnar's eyes on: chips,
      grouped shelf, starter import, "Paprika" search, quick tags.
- [ ] Picker collapse chip ("Show all N") untested with >3 recipes
- [ ] Row reorder (drag) in the manual entry editor
- [ ] Density table is ~30 staples — a volume line that misses it stays
      uncovered by design; grow the table from real recipes, not guesses
- [ ] Manual-entry links die when a line is edited (keyed by line text) —
      fine for v1, revisit if it annoys
- [ ] Meal names editable in settings (the engine already reads them; no UI)
- [ ] "Copy to date" in the UI (`DiaryModel.copyMealFrom` exists, no door)
- [ ] Nutrition detail for a day: the full nutrient table, not just the macros
- [ ] Water, and a weight log, if Arnar ever wants them — not scheduled

## Not doing — say no out loud
- Exercise, weight, water, steps. That is a fitness tracker, not a recipe app.
- A food database of our own. Open Food Facts and the user's own foods, nothing else.
- Streaks, badges, "you've earned it". Not the bet.
