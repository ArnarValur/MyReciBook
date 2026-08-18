# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-19 — checkpoint

## 📍 Now
- Phase: build. Extraction gate passed.
- Link import shipped: share a URL from any app → review. Free path reads the
  page's recipe JSON-LD (no AI call); pages without it fall back to Gemini over
  the page text (costs one AI call, same as a screenshot). Both proven on S21.
- Link fetches ride NetBridge (platform HTTP stack) — dart:io's parser dies on
  Fastly's chunked trailers; Cronet was rejected by AGP 9's namespace rule.
- Cover toggle on link imports: site hero photo (JSON-LD image / og:image),
  shrunk to 1080px JPEG, default on, user decides. Recipe files carry
  source.type "link" + url; screenshot files unchanged byte-for-byte.
- Unit display pill live; metric mode leaves tsp/tbsp as written (spoons are
  universal — Arnar). Link-imported lines have no parsed qty/unit yet.
- Pantry on main: barcode scan → Open Food Facts, pantry tab, per-100g macros,
  ingredient → product linking. Grocery list merges with pantry hints.
- On-device builds only via app/deploy-s21.sh; keyless builds name themselves.
- Current S21 install: 2026-08-19 release build with keys, link import + cover
  toggle + spoons fix live.
- Test suite 527 green serially. Never audited.
- Known gaps: dangling product link on delete · one barcode per photo · 46 older
  products keep seven values until rescanned · no product edit screen ·
  "not measured" prints as 0 · link-import failure copy is honest but final —
  no in-review retry-as-screenshot shortcut.
- Fair-use cap: nothing measured yet. Text fallback burns AI calls.
- Extraction proxy built, not deployed.

## 🚀 Active tracks
- nutrition — open: density table → per-serving → nutrition badge. Link-import
  ingredient parse added as an open item. No remembered links, no inventory.
- mvp-build — billing seam open, unstarted.

## ⚠️ Blockers
- None.

## 📌 Parked
- Proxy deploy · durable cap store · serving rescale · step ↔ ingredient chips ·
  label-photo fallback · manual product entry · meal-plan totals · multi-barcode
  per image · orphan image cleanup · accessibility pass · Dropbox production
  approval · Play signing key backup.
