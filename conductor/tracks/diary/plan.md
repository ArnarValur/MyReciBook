# diary

**Goal:** MyFitnessPal's meal diary on MyReciBook's own foundations — log what you
ate into a day, from the pantry, from a recipe, or typed in, and see the day total
against a goal. This is the piece that makes pantry, scanner and recipes one app.

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

## Weld-time item — product photos on every card (Arnar 2026-08-27)
- Pantry rows show a product's photo when it has one. Diary lines and the add
  sheet do not — same product, two different faces.
- Recipes have the same gap wherever a row draws the book fallback instead of
  the cover.
- TENSION with mockup 1a, which is deliberate, not an oversight: "entry
  avatars say where a line came from: book = logged from a recipe, fridge =
  from the pantry". The avatar carries PROVENANCE; a photo carries IDENTITY.
  Showing the photo wins the identity and loses the provenance.
  Unsettled — Arnar's call at the weld: photo with a small provenance badge in
  the corner, or photo simply replaces the icon.
- Do it after the four design agents land; they own diary_tab, add_food_sheet
  and pantry_tab right now.

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
