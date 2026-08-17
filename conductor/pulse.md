# Pulse — MyReciBook
*State only. REWRITTEN at every checkpoint, never appended. Cap 60 lines.*

> **Updated:** 2026-08-18 by checkpoint (short session — pulse hygiene only)
## 📍 Now
- Phase: build, unblocked. T1 closed. Gates live in context.md §4 — they are
  not status, don't report them unless one is actually being called.
- PANTRY SHIPPED THE WHOLE WAY and IS ON MAIN (b06affd; poc/pantry-follow
  folded and deleted, tree clean, in sync with origin). Proven on his S21:
  collect-mode barcode scan (3s cooldown) → OFF lookup → one JSON per
  product · pantry tab on nav slot 2 (kPantryEnabled; false restores
  Unlock) · per-100g macro detail · user photo per product · ingredient
  long-press → product link (product_ref) w/ search + photo thumbnails.
- PANTRY NOW LIVES IN THE USER'S FOLDER — `pantry/<stem>.json` +
  `pantry/images/*` joined the mirrored sync layout; SAF-backed store; a
  boot migration moved Arnar's 28 products + 3 photos into
  /sdcard/MyReciFolder/pantry and drained the old app-private dir
  (verified on-device by Hermes). Files-you-own gap CLOSED; Drive/Dropbox
  carry the pantry like recipes.
- GROCERY tiers 1+2 in: staple rows show bare names (no "2 cups sugar") ·
  rows from linked ingredients carry product_ref and show a muted "in your
  pantry" hint (hint-only — never removes/checks) · two rows with the same
  ref merge with certainty instead of a text suggestion.
- TESTS: FULL SUITE 454/454 GREEN, run serially (tech rule 13) — the first
  complete run in a while, not just touched files. Still unaudited by Arnar.
- OFF evidence: 15/15 shelf barcodes (spikes/off_barcode_lookup.sh), then 28
  real products. Coverage risk for T5 = retired. DISCOVERY: the ingredient
  qty/unit/item split already existed in D1's schema AND the extractor fills
  it — T5's "Phase 0" cost nothing; linking is the real frontier.
- GAPS accepted: dangling product_ref after a product delete is silent ·
  one barcode per gallery image · mergeSuggestions can still text-suggest a
  pair carrying two DIFFERENT refs · restored remote photos appear after
  the next pantry rescan.
- PLAY: developer profile IN PROGRESS (Arnar) — expected ~2026-08-18. Then
  fee → Console app + one-time product → billing 3g into the Unlock seam.
- D2 PROXY BUILT, NOT DEPLOYED (cap strawman 100/mo); versioning 0.5.0+2
  strawman awaits him. Promo codes at launch (no Play gifting).
- Turn-7 design queue: collapsing hero ratify · manual entry · edit copy ·
  batch edges · error-log door · pantry surfaces (all built minimal).
- OPEN (Arnar): design authority in git (design-system gitignored).
- KEYSTORE BACKUP: raised 2026-08-18, dropped as premature — nothing is
  uploaded to Play, so a lost upload key costs nothing today. Re-raise it
  only at the first Play upload, not before.

## 🚀 Active tracks
- T5 nutrition — capture + linking + sync SHIPPED (see Now). Plan:
  conductor/tracks/T5-nutrition/plan.md. Next in-track: remembered links
  (N7) → unit table → nutrition badge. NO inventory tracking (named trap).
- T3 mvp-build — billing 3g next engine seam, waiting on Play profile.
- T2 landing-page — myrecibook.com registered; not built yet.

## ⚠️ Blockers
- Billing 3g ← Play developer profile (Arnar) → fee → Console app+product.
- Proxy deploy + listed cap number ← Arnar's gcloud/billing decision.

## 📋 Next queue (sequence — no schedule)
1. Arnar: finish Play profile → pay fee → Console app + one-time product.
2. Billing 3g: real purchase into the Unlock seam.
3. Arnar decisions: proxy deploy + cap · versioning · keystore backup ·
   design-authority-in-git.
4. Pantry follow-ons: N7 remembered links DECLINED by Arnar 2026-08-18 ("not
   for now") — do not re-queue it. Unit table still open (feeds nutrition
   badge AND grocery package math, N8 tier 3).
5. Design turn 7 · T2 landing page · D9 link spike when his links arrive.

## 📌 Parked
- Proxy DEPLOY · durable cap store · Play Integrity · inbox strip ·
  serving-rescale · step↔ingredient chips · camera-roll nudge · cover
  auto-crop 2 · AI covers · telemetry (D8) · arm B ocr_dump · $2.99 top-up
  UNCONFIRMED · handwriting UNTESTED · ADR 0001 graduation due · multi-image
  shares · token store → keystore · orphan-image GC · schema-v2 policy ·
  a11y pass · fixture superset · Dropbox prod approval · Play App Signing
  cert (rules 9+10) · OFF image_url enrichment · multi-barcode per image ·
  label-photo fallback · manual product entry · PlanTab wake-up (diary).
