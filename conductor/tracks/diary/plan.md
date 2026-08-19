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

## Open
- [ ] The sync case: the layout confines to root *.json + images/ + pantry/, so
      day files do not travel to Drive or Dropbox yet. Biggest gap.
- [ ] Reach the create/edit-food screen from the pantry too — it only opens from
      the diary's Add food today
- [ ] Meal names editable in settings (the engine already reads them; no UI)
- [ ] Log a recipe by servings — needs the nutrition track's per-serving
      calculator first
- [ ] Manual recipe entry revamp (Arnar 2026-08-19): compose a recipe FROM
      pantry items — pick a product per ingredient while writing, so the
      recipe is calorie-computable from birth instead of linked afterwards.
      Same calculator dependency; design turn is Arnar's (no mockup covers it).
- [ ] "Copy to date" in the UI (`DiaryModel.copyMealFrom` exists, no door)
- [ ] Nutrition detail for a day: the full nutrient table, not just the macros
- [ ] Water, and a weight log, if Arnar ever wants them — not scheduled

## Not doing — say no out loud
- Exercise, weight, water, steps. That is a fitness tracker, not a recipe app.
- A food database of our own. Open Food Facts and the user's own foods, nothing else.
- Streaks, badges, "you've earned it". Not the bet.
