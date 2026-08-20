# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-20 — checkpoint

## 📍 Now
- Phase: build. Version 0.7.0+4 on the S21, release build with keys, eyes-verify pending.
- Unified recipe editor: ONE row-editor screen for New and Edit ("New
  Recipe", not "Type it in yourself"). Edit pre-fills, saves in place,
  keeps the original-screenshot pane; ImportReviewScreen is import-review
  only. Re-parse on line edit — no stale parse behind new text.
- Row chips are inline-editable; "Fix the reading" popup is gone. Unit
  options follow the linked product's base unit (ml → ml/dl/l/ss/ts,
  g → g/kg/stk).
- Linked rows display the product name, one line, no sub-line — editor and
  recipe detail both, via linkedIngredientLine. Typed text stays in the
  file; unlink restores it.
- Editor metadata: servings stepper, min/hr duration field, cover picker
  with camera (ui/widgets/editor_fields.dart) — manual recipes now store
  structured servings/time, not raw-only.
- Add food picker: Recent → recipes (strip of 3 + Show all) → pantry;
  search reaches recipes.
- Diary chain e2e-tested: links → picker kcal → snapshot entry; snapshot
  survives product edits; unlinked recipe logs honest-empty.
- Editor-rewrite tests (manual_entry, edit_recipe) not yet run after the
  final edits. Phase-1 work verified 666 green before the rewrite. Full
  suite: deferred to the release gate by decision 2026-08-20.

## 🚀 Active tracks
- diary — recipe→pantry→diary thread closed in code, pending suite run +
  S21 verify.
- nutrition — open: grocery package-size math, label-photo fallback.
- mvp-build — billing seam open, unstarted. GCP/Firebase dev project
  created (MyReciBook-Dev, ID gen-lang-client-0166122901); production
  project separate at go-live.

## ⚠️ Blockers
- None.

## 📌 Parked
- Proxy deploy · durable cap store · serving rescale · step ↔ ingredient chips
  · label-photo fallback · meal names UI · copy-to-date UI · day nutrient
  table · row reorder in manual entry · multi-barcode per image · orphan image
  cleanup · accessibility pass · Dropbox production approval · Play key backup.
