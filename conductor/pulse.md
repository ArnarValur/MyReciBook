# Pulse — MyReciBook
*State only. REWRITTEN at every checkpoint, never appended. Cap 60 lines.*

> **Updated:** 2026-08-17 late-night by checkpoint (follow-on dispatched)
## 📍 Now
- Phase: pre-project (kickoff 2026-08-20, 3 days); building unblocked, gates
  decide ship/stop (context.md §4). GATE 1 PASSED; T1 closed.
- IN FLIGHT at checkpoint: branch poc/pantry-follow open (= main), two
  worktree agents running — (a) pantry/ sync case incl. store-in-user-
  folder + 28-product migration (briefed with delete-safety rules: layout
  filter stays strict, old manifests/clients must skip pantry, never
  "vanished"→delete); (b) grocery tiers 1+2 (staples hide qty · pantry
  hint via productRef, hint-only). Their branches: poc/pantry-sync,
  poc/grocery-tiers. NOT merged — sync gets a hard review first
  (data-loss surface). Next session: collect reports → review → wire →
  test → S21.
- PANTRY POC LIVE ON THE S21 — FOLDED to main 2026-08-17 night (Arnar:
  "I want this in main ofc"). Working tonight, his eyes on all of it: barcode
  collect-mode scan (beep-beep, 3s cooldown) → OFF lookup → one JSON per
  product in app docs · pantry tab borrows nav slot 2 (kPantryEnabled=true
  on dev; false restores Unlock) · product detail w/ per-100g macros ·
  user photo per product (cover mechanics) · ingredient long-press →
  link to pantry product (product_ref, additive) w/ search + thumbnails.
- OFF evidence: 15/15 shelf barcodes (spikes/off_barcode_lookup.sh) then
  28 real products scanned. Coverage risk for T5 = retired.
- DISCOVERY: the ingredient qty/unit/item split already exists in D1's
  schema AND the extractor fills it (his real files prove it) — T5
  "Phase 0" costs zero. Linking is the actual frontier.
- POC gaps, accepted: pantry does NOT sync (layout confines to root
  *.json + images/ — needs a pantry/ case) so products+photos don't yet
  follow the user's folder · dangling product_ref after product delete ·
  one barcode per gallery image.
- Tests: ~48 new green tonight (off_client 10 · product store/roundtrip 38
  incl. 6 photo · pantry model 6 · ingredient link 4 — only these ran;
  full suite not re-run; still unaudited by Arnar; tech rule 13).
- PLAY: developer profile IN PROGRESS (Arnar) — expected ~2026-08-18.
  Then fee → Console app + one-time product → billing 3g wires the real
  purchase into the Unlock seam.
- D2 PROXY BUILT, NOT DEPLOYED (cap strawman 100/mo); versioning 0.5.0+2
  strawman awaits him. Promo codes at launch (no Play gifting).
- Turn-7 design queue: collapsing hero ratify · manual entry · edit copy ·
  batch edges · error-log door · NEW: pantry surfaces (tab, detail,
  link picker — all built minimal, undesigned).
- OPEN (Arnar): design authority in git (design-system gitignored).

## 🚀 Active tracks
- T5 nutrition — POC BUILT (see Now). Plan: conductor/tracks/T5-nutrition/
  plan.md — brainstorms banked 2026-08-17: remembered links · grocery
  product-ization (staples hide qty → "you have it" hint → package math) ·
  NO inventory tracking, ever (named trap).
- T3 mvp-build — billing 3g next engine seam, waiting on Play profile.
- T2 landing-page — myrecibook.com registered; live 2 Sep (Gate 2 needs it).

## ⚠️ Blockers
- Billing 3g ← Play developer profile (Arnar) → fee → Console app+product.
- Proxy deploy + listed cap number ← Arnar's gcloud/billing decision.

## 📋 Next queue (sequence — no schedule)
1. Arnar: finish Play profile → pay fee → Console app + one-time product.
2. Billing 3g: real purchase into the Unlock seam.
3. Arnar decisions: proxy deploy + cap · versioning · keystore backup ·
   design-authority-in-git.
4. Pantry follow-ons: sync case + grocery tiers IN FLIGHT (see Now) →
   then remembered links → unit table (feeds nutrition badge AND
   package math).
5. Design turn 7 · T2 landing page · D9 link spike when his links arrive.

## 📌 Parked
- Proxy DEPLOY · durable cap store · Play Integrity · inbox strip ·
  serving-rescale · step↔ingredient chips · camera-roll nudge · cover
  auto-crop 2 · AI covers · telemetry (D8) · arm B ocr_dump · $2.99 top-up
  UNCONFIRMED · handwriting UNTESTED · ADR 0001 graduation due · multi-image
  shares · token store → keystore · orphan-image GC · schema-v2 policy ·
  a11y pass · fixture superset · Dropbox prod approval · Play App Signing
  cert (rules 9+10) · OFF image_url enrichment · multi-barcode per image ·
  nutrition badge math (after unit table) · PlanTab wake-up (diary).
