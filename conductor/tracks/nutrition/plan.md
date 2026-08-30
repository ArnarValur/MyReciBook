# nutrition

**Status: DORMANT** — Arnar 2026-08-30. Not active, not blocked, not hanging.
The track is built out; the one open item needs a meal plan that does not exist.

**Goal:** per-serving nutrition on every recipe, fed by the user's own barcode scans
and label photos, in any country. The meal plan becomes the food diary.

**Division:** Arnar owns UI and design — the mockups are the design answer, so engine
work never waits on skin. Agent owns the engine. New surfaces stay behind a feature
flag until wired.

**No new backend.** Open Food Facts lookup only.

## Built and on main
- [x] Barcode scan, collect mode, 3s cooldown
- [x] Open Food Facts lookup with a three-way result: found / not found / error
- [x] One JSON per product in the user's folder, syncs like recipes
- [x] Pantry tab, product detail with per-100g macros, user photo per product
- [x] Ingredient long-press → product link, with search and photo thumbnails
- [x] Grocery list: bare staple rows, "in your pantry" hint, same-product merge
- [x] Full open nutrient list saved instead of seven fixed slots
- [x] Unit display toggle (As written / Metric / US in settings; local math at
      render on ingredients, steps and cook mode incl. °F→°C and inches;
      recipe file untouched; stick/pinch/egg pass through) — domain/units.dart
- [x] Metric mode leaves tsp/tbsp as written — spoons are universal
      (Arnar 2026-08-19); imperial still prints small ml as spoons

## Built and on main — confirmed against the code 2026-08-30
- [x] Density table for staples — densityTable in domain/recipe_nutrition.dart,
      read by ingredientGrams, so a cup of flour weighs grams
- [x] Per-serving calculator — recipeNutrition() + servingsAmount()
- [x] Nutrition badge on the recipe — NutritionBlock in recipe_detail_screen
- [x] Product edit screen — ui/pantry/product_page.dart, one autosaving page
- [x] Manual product entry — ui/pantry/manual_product_screen.dart
- [x] Meal-plan totals — Meal.total and Day.total in domain/diary.dart
- [x] Label-photo read — GeminiExtractor.extractLabel + domain/label_read.dart,
      wired into manual product entry
- [x] Package-size math in the grocery list — 2026-08-30. Pack size parsed off
      Product.quantity (units.dart), count rounded up, row reads
      "750 g Flour · 2 × 500 g". Silent below 2 packs and on bare numbers,
      worded sizes, or cups against a weight pack.

## Verified in the code 2026-08-30 — the list below was stale for three sessions
- [x] Density table for staples — `densityTable` + `_densityFor` feed
      `ingredientGrams`, domain/recipe_nutrition.dart. 30 staples incl. Norwegian.
- [x] Link imports no longer stall on null qty/unit/item — `effectiveQty` parses
      the raw line when the file carries no parse.
- [x] Per-serving calculator — `RecipeNutrition.perServing`, null when the recipe
      never says how many it serves.
- [x] Nutrition badge on the recipe — recipe_detail_screen.dart, shown only when
      there is something honest to say, with its "N of M" basis.
- [x] Product edit screen — ui/pantry/product_page.dart, one autosaving page.
- [x] Package-size math in the grocery list — 2026-08-30. Pack size parsed off
      Product.quantity (units.dart), count rounded up, row reads
      "750 g Flour · 2 × 500 g". Silent below 2 packs and on bare numbers,
      worded sizes, or cups against a weight pack.
- [x] Label-photo fallback through the extraction pipeline — domain/label_read.
- [x] Manual product entry — ui/pantry/manual_product_screen.dart, the quarter
      "+" beside Scan.
Proof: recipe_nutrition, label_read, product_page, pantry_model and
recipe_diary_chain tests run together 2026-08-30 — 79 pass, 1 fail, and that
one fail is stale (it taps a product in the picker, which now opens folded
after the 2026-08-30 shelf rework — lib is right, assert is old).

## Open — the whole remaining track
- [ ] Meal-plan totals. BLOCKED, and not by nutrition: there is no meal plan.
      ui/plan_tab.dart is a 52-line "lands post-alpha" empty state, no plan
      engine exists. The diary already totals per meal and per day
      (domain/diary.dart) — the math is built, the planner is not.
- [ ] Serving labels ignore the units toggle — the note at the bottom of this file.
- [ ] The grocery pack math cannot reach the density table, so cups against a
      weight pack stay silent. Wiring `_densityFor` into units.dart closes it.

## Declined — do not re-queue
- Remembered ingredient → product links. Declined by Arnar 2026-08-18.
- Inventory tracking. Named as a trap.

## Known gaps
- A deleted product leaves a silent dangling link on the ingredient.
- One barcode per gallery image.
- The grocery list can still text-suggest merging two rows that carry different products.
- A photo restored from remote only appears after the next pantry rescan.
- Some "not measured" values from Open Food Facts print as 0.

## Found 2026-08-22 — serving labels ignore the units toggle
`convertUnits` is called only on recipe ingredient lines and steps
(recipe_detail, cook_mode, recipe_pdf). Serving labels on products and in the
diary never pass through it, so the starter-food table's "1 cup" / "1 tsp" /
"1 medium" show as written no matter what the units pill says. A metric user
sees cups. This is a units bug, not an i18n one — surfaced while counting
strings for the i18n sweep.
