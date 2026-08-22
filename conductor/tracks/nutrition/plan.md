# nutrition

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

## Open
- [ ] Density table for staples (cup of flour → grams; volume stays volume until
      then). Same parse should feed serving rescale and grocery merge.
- [ ] Link imports (JSON-LD path) leave qty/unit/item null — ingredient parse
      needed before the unit toggle and nutrition math cover them.
- [ ] Per-serving calculator
- [ ] Nutrition badge on the recipe
- [ ] Product edit screen — Open Food Facts data is sometimes wrong and 46 older
      products keep the old seven values until rescanned
- [ ] Package-size math in the grocery list (waits on the unit table)
- [ ] Label-photo fallback through the extraction pipeline
- [ ] Manual product entry
- [ ] Meal-plan totals

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
