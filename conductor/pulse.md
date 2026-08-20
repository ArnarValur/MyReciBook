# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-20 — checkpoint

## 📍 Now
- Phase: build. 0.8.0+5 in the tree; the S21 runs the phase-1-3 build
  (pre-starter-foods) — redeploy pending Arnar's go.
- Pantry categories live end to end: OFF auto-tag on scan + bulk refresh
  (domain/product_categories.dart, four-tier match; Nordic products often
  ship empty food_groups_tags — covered), chip row + grouped shelf,
  category filter in the Add-food drawer, emoji labels via system Noto.
- ONE product picker (ui/widgets/product_picker_sheet.dart) serves recipe
  detail + editor linking: search, synonyms, category chips. Old ad-hoc
  drawers deleted. Edit-screen tag pills = productCategories, one list.
- Quick category pills on the product page; setTags keeps userEdited as-is.
- Starter foods built: 149 curated items in 3 packages (Veggies 65,
  Fruits & Berries 49, Spices 35), domain/starter_foods.dart, import door
  on the pantry tab, EU-carb conversion in code, Product.synonyms
  searchable in pickers. VALUES UNVERIFIED against USDA — Arnar owns the
  verification agent run; patch that one file.
- TEST LAW (workflow.md): no flutter test runs unless Arnar says "test
  it"; flutter analyze is the default check. Full suite only at release
  gate. Runs he orders: timeout 120, visible output.

## 🚀 Active tracks
- diary — categories phases 1-4 in code; open: S21 verify of 2-4,
  starter-value verification, three test files still pinned to the
  deleted link drawer (manual_entry, edit_recipe, recipe_detail_link).
- nutrition — open: grocery package-size math, label-photo fallback.
- mvp-build — billing seam open, unstarted. Dev GCP project exists
  (MyReciBook-Dev, gen-lang-client-0166122901).

## ⚠️ Blockers
- None.

## 📌 Parked
- Category icon/colour pass (Arnar researching; emoji placeholder live) ·
  proxy deploy · durable cap store · serving rescale · step ↔ ingredient
  chips · label-photo fallback · meal names UI · copy-to-date UI · day
  nutrient table · row reorder · multi-barcode per image · orphan image
  cleanup · accessibility pass · Dropbox production approval · Play key
  backup.
