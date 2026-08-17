# Pulse — MyReciBook
*State only. REWRITTEN at every checkpoint, never appended. Cap 60 lines.*

> **Updated:** 2026-08-17 by checkpoint (S21 session: Drive smoke passed)
## 📍 Now
- Phase: pre-project (kickoff 2026-08-20, 3 days); building unblocked, gates
  decide ship/stop (context.md §4). GATE 1 PASSED; T1 closed.
- DRIVE SMOKE PASSED 2026-08-17 — Arnar on a fresh dev.env build on the S21:
  connect, save, sync, reopen all clean. Queue head since 08-09 is closed.
  Both connectors now proven on-device (Dropbox passed 08-09).
- S21 carries current main + today's change: the Unlock tab's "Why not a
  subscription?" collapse is now a STATIC CARD (Arnar's call on the installed
  build). Eyeball pass on Unlock tab + grid ⇄ list toggle PASSED.
- Covers: STORE LAYER TESTED (6 new tests — copy-in, jpg↔png swap, remove
  takes bytes, promote = ref not copy, delete takes cover, edit keeps it).
  UI tap-choreography tests DROPPED 2026-08-17 (Arnar: "just drop it") —
  do not re-queue (behavioral 16). One data wipe on the S21 agreed 08-17
  (foreign-keystore install; tech rule 15).
- Tests: 350 app on paper (344 + 6 new) + 10 proxy; today only touched files
  re-ran green (recipe_store 21/21, unlock_tab 3/3). Full suite not re-run;
  still unaudited by Arnar; flaky under parallel isolates (tech rule 13).
- PLAY: developer profile IN PROGRESS (Arnar, preliminaries) — expected
  ~2026-08-18. Then fee → Console app + one-time product → billing 3g wires
  the real purchase into the Unlock seam.
- D2 PROXY BUILT, NOT DEPLOYED (key server-side, cap strawman 100/mo);
  deploy = his gcloud call ($0 tier) + listed cap. Versioning 0.5.0+2
  strawman awaits him. GIFTING IMPOSSIBLE on Play — promo codes at launch.
- Turn-7 design queue: collapsing hero ratify · manual entry · edit copy ·
  batch edges (grep DEVIATION) · error-log door (dialog UNDESIGNED).
- OPEN (Arnar): design authority in git (unzipped design-system gitignored).

## 🚀 Active tracks
- T3 mvp-build — Drive smoke PASSED; billing 3g is the next engine seam,
  waiting on the Play profile. Plan: conductor/tracks/T3-mvp-build/plan.md
- T2 landing-page — myrecibook.com registered; live 2 Sep. Channels →
  docs/marketing-channels.md (5 venues; seed accounts).

## ⚠️ Blockers
- Billing 3g ← Play developer profile (Arnar, ~18 Aug) → fee → Console
  app + product setup.
- Proxy deploy + listed cap number ← Arnar's gcloud/billing decision.

## 📋 Next queue (sequence — no schedule)
1. Arnar: finish Play profile → pay fee → Console app + one-time product.
2. Billing 3g: real purchase into the Unlock seam; flip kSpreadWordEnabled
   when the listing is live.
3. Arnar decisions: proxy deploy + cap · versioning · keystore backup ·
   design-authority-in-git.
4. Design turn 7 · T2 landing page (live 2 Sep — Gate 2 needs it).
5. D9 link spike WHEN his 5–10 real test links arrive (asked 2026-08-15).

## 📌 Parked
- Proxy DEPLOY (D2: before 11 Dec) · durable cap store (4d) · Play Integrity ·
  inbox strip · serving-rescale · step↔ingredient chips · camera-roll nudge ·
  cover auto-crop tier 2 · AI covers · telemetry (D8) · arm B ocr_dump ·
  $2.99 top-up UNCONFIRMED · handwriting UNTESTED · ADR 0001 graduation due ·
  multi-image shares one recipe · token store → keystore pre-prod · orphan-
  image GC · schema-v2 read policy · full a11y pass (16 Nov) · fixture
  superset · Dropbox production approval · Play App Signing cert at first
  upload needs BOTH a Drive client (rule 9) AND its manifest entry (rule 10).
