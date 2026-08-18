# Pulse — MyReciBook
*State only. REWRITTEN at every checkpoint, never appended. Cap 60 lines.*

> **Updated:** 2026-08-18 by checkpoint (behavioral rules file is empty, by Arnar)

## 📍 Now
- Phase: build. Tree clean, in sync with origin. T1 closed.
- BEHAVIORAL RULES ARE GONE — Arnar emptied conductor/agent-rules/behavioral.md
  himself (158b0ec) and stripped graduation from /checkpoint. Do not restore it,
  do not start a new rule list. technical.md (158 lines) is untouched and live.
- PANTRY SHIPPED, ON MAIN (b06affd). Proven on his S21: collect-mode barcode
  scan (3s cooldown) → OFF lookup → one JSON per product · pantry tab on nav
  slot 2 (kPantryEnabled; false restores Unlock) · per-100g macro detail ·
  user photo per product · ingredient long-press → product link (product_ref)
  w/ search + photo thumbnails.
- PANTRY LIVES IN THE USER'S FOLDER — `pantry/<stem>.json` + `pantry/images/*`
  joined the mirrored sync layout; SAF-backed store; boot migration moved 28
  products + 3 photos into /sdcard/MyReciFolder/pantry and drained the old
  app-private dir. Drive/Dropbox carry the pantry like recipes.
- GROCERY tiers 1+2 in: staple rows show bare names · rows from linked
  ingredients carry product_ref + a muted "in your pantry" hint (hint-only) ·
  two rows with the same ref merge with certainty, no text suggestion.
- TESTS: full suite 454/454 green, run serially (tech rule 13). Unaudited.
- OFF evidence: 15/15 shelf barcodes, then 28 real products. T5 coverage risk
  retired. The ingredient qty/unit/item split already exists in D1's schema
  and the extractor fills it — linking is the real frontier.
- GAPS accepted: dangling product_ref after a product delete is silent · one
  barcode per gallery image · mergeSuggestions can still text-suggest a pair
  carrying two DIFFERENT refs · restored remote photos appear after the next
  pantry rescan.
- CAP: fair-use number has an evidence path — conductor/tracks/T3-mvp-build/
  cap-brief.md. gemini-3.6-flash intro pricing DOUBLES 2027-01-01, so all cap
  math runs at the 2027 price. Nothing measured yet.
- D2 PROXY BUILT, NOT DEPLOYED (cap strawman 100/mo). Promo codes at launch.
- Turn-7 design queue: collapsing hero ratify · manual entry · edit copy ·
  batch edges · error-log door · pantry surfaces (all built minimal).

## 🚀 Active tracks
- T5 nutrition — capture + linking + sync shipped. Plan: conductor/tracks/
  T5-nutrition/plan.md. Open in-track: unit table → nutrition badge.
  N7 remembered links DECLINED — do not re-queue. NO inventory tracking.
- T3 mvp-build — engine complete through sync. Billing seam open, unstarted.
- T2 landing-page — myrecibook.com registered; not built.

## ⚠️ Blockers
- None. Your own items are not tracked here — you report when they land.

## 📋 Next queue
- EMPTY — awaiting your picks. I don't fill this myself.

## 📌 Parked
- Proxy DEPLOY · durable cap store · Play Integrity · inbox strip ·
  serving-rescale · step↔ingredient chips · camera-roll nudge · cover
  auto-crop 2 · AI covers · telemetry (D8) · arm B ocr_dump · $2.99 top-up
  UNCONFIRMED · handwriting UNTESTED · ADR 0001 graduation due · multi-image
  shares · token store → keystore · orphan-image GC · schema-v2 policy ·
  a11y pass · fixture superset · Dropbox prod approval · Play App Signing
  cert (rules 9+10) · OFF image_url enrichment · multi-barcode per image ·
  label-photo fallback · manual product entry · PlanTab wake-up (diary) ·
  keystore backup (revisit at first Play upload, not before).
