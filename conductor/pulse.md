# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-18 — checkpoint

## 📍 Now
- Phase: build. Extraction gate passed.
- Conductor rebuilt small: 8 files, ~200 lines. agent-rules/ is empty by design —
  nothing writes a rules file there unasked. Arnar trimmed context and tracks himself.
- Pantry ships on main: barcode scan → Open Food Facts lookup → one JSON per product,
  pantry tab, per-100g macros, user photo per product, ingredient → product linking.
- Pantry files live in the user's own folder and sync like recipes; 28 products
  migrated on-device.
- Grocery list: staple rows show bare names, linked rows show a muted "in your pantry"
  hint, two rows with the same product merge with certainty.
- Full nutrient list saved, not seven fixed slots; kept in Open Food Facts' own
  units, screen converts down. Uncommitted in the tree.
- Test suite ran 454 green serially at the last check. Never audited.
- Known gaps: deleted product leaves a silent dangling link · one barcode per photo ·
  46 older products keep the old seven values until rescanned · Open Food Facts data
  is sometimes wrong, no product edit screen · "not measured" prints as 0.
- Fair-use cap: nothing measured yet.
- Extraction proxy built, not deployed.

## 🚀 Active tracks
- nutrition — open: unit table → nutrition badge. Remembered links declined by Arnar,
  do not re-queue. No inventory tracking.
- mvp-build — billing seam open, unstarted.

## ⚠️ Blockers
- None on my side. Arnar's own items are not tracked here.

## 📋 Next queue
- Empty. Awaiting Arnar's picks. I do not fill this myself.

## 📌 Parked
- Proxy deploy · durable cap store · serving rescale · step ↔ ingredient chips ·
  label-photo fallback · manual product entry · meal-plan totals · multi-barcode
  per image · orphan image cleanup · accessibility pass · Dropbox production
  approval · Play signing key backup.
