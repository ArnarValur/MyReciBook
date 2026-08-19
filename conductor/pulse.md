# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-19 — checkpoint

## 📍 Now
- Phase: build. Version 0.6.0+3, on the S21, release build with keys.
- Meal diary shipped end to end: nav slot 3 is "Food" (Diary | Pantry behind a
  segmented control), day walker, totals vs goal, four meals, add/edit/remove,
  quick add, recents, copy-meal engine.
- One JSON per logged day at <tree>/diary/<YYYY-MM-DD>.json. Diary now rides
  the sync layout, so days travel to Drive/Dropbox like recipes and pantry.
- Diary entries SNAPSHOT their nutrition — correcting a product later never
  rewrites a day already lived. `ref` is for re-logging, never arithmetic.
- Products gained servings (label + grams), tags, and a user_edited flag.
  Bulk OFF refresh skips hand-edited products and confirms with counts; the
  detail page has a per-product refresh that may override, and an edit door.
- Per-serving calculator lands: deterministic ingredient parse at compute
  time + a ~35-entry density table (Norwegian keys included). Nutrition card
  on recipe detail, hidden until something is linked.
- Manual entry is a row editor: lines structure themselves into qty/unit/item
  chips (tappable to correct), a pantry Link chip per row, numbered steps.
- Gemini model is gemini-3.5-flash-lite everywhere that bites — app, proxy
  allowlist, spike harness, docs.
- Test suite 637 green serially, plus proxy 10. Never audited.

## 🚀 Active tracks
- diary — the food-logging chain is on the phone. Open: the recipe→diary
  thread does not hold for older recipes (see blockers).
- nutrition — density table, calculator and badge landed via diary. Open:
  grocery package-size math, label-photo fallback.
- mvp-build — billing seam open, unstarted.

## ⚠️ Blockers
- The recipe→pantry→diary thread only holds for recipes born in the new row
  editor with links tapped. Diagnosed 2026-08-19, unfixed:
  · "Edit recipe" goes to ImportReviewScreen.edit, which has NO pantry
    linking — so an imported recipe can never get links. It preserves
    productRef on save (copyWith), but editing a line keeps the OLD
    qty/unit/item, leaving a stale parse behind the new text.
  · Recipes render BELOW the whole pantry list in Add food — a very long
    scroll on a real shelf.
  · Result Arnar saw: a recipe logged to Breakfast with no nutrition.
- No end-to-end test covers recipe-with-links → picker → logged entry.

## 📌 Parked
- Proxy deploy · durable cap store · serving rescale · step ↔ ingredient chips
  · label-photo fallback · meal names UI · copy-to-date UI · day nutrient
  table · row reorder in manual entry · multi-barcode per image · orphan image
  cleanup · accessibility pass · Dropbox production approval · Play key backup.
