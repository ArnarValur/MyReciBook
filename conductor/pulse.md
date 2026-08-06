# Pulse — MyReciBook
*State only. REWRITTEN at every checkpoint, never appended. Cap 60 lines.*

## 📍 Now
- Phase: pre-project (kickoff 2026-08-20); constraint 4 amended — building
  unblocked, gates decide ship/stop (context.md §4).
- Engine PROVEN on device (2026-08-06): 77 tests green; Arnar's real import
  passed end-to-end on the S21, incl. add-screenshot method re-extract.
- SKIN LIVE same night: all 12 hi-fi screens implemented (as-built detail →
  docs/design/skin-implementation-map.md) — 7 alpha-wired on proven flows
  (3a/3c/3d/3e/3f + 4b/4c states), 5 post-alpha as dev-gallery previews
  (long-press wordmark). Light+dark ship; fonts bundled (rule 8); analyze
  clean; APK verified on the S21 (catches detail → skin-implementation-map).
- Schema v1: original_images ARRAY · extraction.mode enum · optional favorite
  bool (T1 D1; emitted only when true — old files round-trip byte-identical).
- Arnar owns design; agent owns engine + skin. Skins replace widgets, never flows.
- T3 D10 monetization: 3 LIFETIME free imports → hard wall → one-time unlock,
  ~$25 anchor (§6.2 Crouton precedent; final price = T4; price stated ON the
  landing page so Gate 2 is price-aware).
- PRE-FESTIVAL BLITZ agreed 2026-08-06 eve (constraint 4 as amended): 4 Code
  nights before 12 Aug — share-sheet+SAF → grocery 4a → batch 3b + manual
  entry → settings + link door D9. Named OUT this week: billing (no Play
  account till 20 Aug) · proxy/cap (post-alpha, P5) · Drive/Dropbox sync
  (OAuth review + constraint 6). App login/account: never — re-affirmed.
  Billing 3g JOINS the blitz if the Play fee lands early (Arnar's offer: pay
  before the w/e on a strong Fri build). Fri target = closed-test-complete.
- T1: arm A judged IN-APP now (D5, 2026-08-06). Smoke PASSED (arm A,
  gemini-3.6-flash, 2 recipes → clean JSON). Gemini free-tier key in
  app/dev.env; ocr_dump APK on disk (arm B ready).

## 🚀 Active tracks
- T1 extraction-spike — arm A in-app (D5); needs 8 more honest recipes
  (unit = recipes/rows, 10 rows total) + arm B run (this w/e possible).
  Plan: conductor/tracks/T1-…/plan.md
- T3 mvp-build — engine + skin done, on device; blitz nights 1–4 queued
  (SAF first). Plan: conductor/tracks/T3-mvp-build/plan.md

## ⚠️ Blockers
- Play Console fee: paid AFTER the festival (starts 12 Aug); registration
  20 Aug morning. Any review snag hits the 19 Oct alpha chain.

## 📋 Next queue
1. Arnar TONIGHT (~25 min): 8 more honest recipes onto the phone (Instagram,
   sites, social; ugly ones welcome; pairs fine) → 10 results.md rows.
2. Arnar TONIGHT (~40 min): arm A through the app (T1 D5) — import each,
   judge y/n on review BEFORE editing, tally + skin notes as you go.
3. Code night 1 (tonight): share-sheet + SAF store (arch §8) — then grocery
   4a → batch 3b + manual entry → settings + D9, one per night.
4. Fri, if the build is strong: Arnar pays Play fee ($25, ~30 min) → identity
   verification starts → billing night + internal track unlock. Festival:
   QR to the closed-test opt-in link — recruit the 12 required testers.
5. This w/e (~1 h 10): copy set → spike/screenshots/ (pairs name-1/name-2),
   arm B: ocr_dump + harness --mode text → results.md → early Gate 1 verdict.
6. Arnar, festival-adjacent: T2 signup/landing page design in Claude Design —
   email capture only, NO accounts, price on the page; live 2 Sep.
7. 20 Aug 09:00 (scheduled): kickoff — registration IF not already done Fri.

## 📌 Parked
- Post-alpha engines still pending after blitz: paywall + billing 3g · storage
  connectors 3h · cap counter 4d ($2.99 top-up UNCONFIRMED, kTopUpEnabled) ·
  camera-roll auto-scan (post-v1). NO login/account page ever. Proxy host:
  NOT GCP (Arnar 2026-08-06) — Workers/Hetzner-class, decided post-alpha.
- Cover-image crop tier 2 (bbox, same call) — spike-gated; tier 1 shipped.
- Snap-a-page handwriting: promise UNTESTED — spike before listing copy (D9).
- ADR 0001 (schema v1) — graduates on Gate-1 pass (incl. favorite).
- T2 landing page build (live 2 Sep target).
