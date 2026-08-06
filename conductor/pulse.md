# Pulse — MyReciBook
*State only. REWRITTEN at every checkpoint, never appended. Cap 60 lines.*

## 📍 Now
- Phase: pre-project (kickoff 2026-08-20); constraint 4 amended — building
  unblocked, gates decide ship/stop (context.md §4).
- Engine PROVEN on device (2026-08-06): 77 tests green, Arnar's real import
  passed end-to-end on the S21, incl. add-screenshot method re-extract.
- SKIN BUILT + ON DEVICE same night (late): Arnar's hi-fi design set (Claude
  Design project → docs/design/handoff.md, full DittoDatto token spec) is
  implemented. Wired on proven flows: import sheet 3a (single-recipe) · review
  3c (flagged-line confirm chips, calm 4c failure) · cookbook 3d (grid, covers
  = screenshot-1 BoxFit.cover, search, chips, 4b empty state) · detail 3e
  (hero + provenance flip, favorite heart) · cook mode 3f (wakelock, step
  timer). Post-alpha screens 3b/3g/3h/4a/4d BUILT as previews behind debug
  dev gallery (long-press wordmark). Light+dark both ship; fonts bundled
  (offline-correct, technical rule 8). 77 tests green, analyze clean, APK
  verified rendering on the S21 (dark mode, real recipe).
- Schema v1: original_images ARRAY · extraction.mode enum · + optional
  favorite bool (T1 D1 amendment; emitted only when true — old files
  round-trip byte-identical).
- Review-note catches honored: delete-toggle OMITTED until engine support ·
  "On this phone" quiet pill · tertiary = heart + paywall badge only.
- Division of labor: Arnar owns design (spec delivered), agent owns engine +
  skin build. Skins replace widgets, never flows.
- Gemini free-tier key in .env → app/dev.env; ocr_dump APK on disk (arm B ready).
- T1 smoke PASSED (arm A, gemini-3.6-flash): 2 multi-image recipes → clean JSON.

## 🚀 Active tracks
- T1 extraction-spike — smoke passed; needs 6 more honest screenshots (English
  web/social) + arm B run. Plan: conductor/tracks/T1-…/plan.md
- T3 mvp-build — engine + alpha skin DONE, on device; next: share-sheet + SAF
  store (arch §8), then Arnar's visual pass on all 12 screens.
  Plan: conductor/tracks/T3-mvp-build/plan.md

## ⚠️ Blockers
- Play Console fee: Arnar pays AFTER the festival (starts 12 Aug); registration
  still 20 Aug morning. Any review snag hits the 19 Oct alpha chain.

## 📋 Next queue
1. Arnar (~20 min): 6 more honest screenshots → spike/screenshots/, pairs as
   name-1/name-2 — completes the Gate-1 test set.
2. Arm B on S21: install spike/out/ocr_dump.apk, OCR the set, adb pull dumps,
   harness --mode text → results.md y/n → Gate 1 verdict (due 30 Aug).
3. Arnar: open the app — the skin is on your phone. Long-press the wordmark
   for the 5 post-alpha screens. Notes → next session tunes.
4. Agent next session: share-sheet plumbing + SAF store (arch §8 budgets).
5. 20 Aug 09:00 (scheduled): kickoff — Play Console registration + spike status.

## 📌 Parked
- Post-alpha wiring (screens built, engines pending): batch queue (D5) ·
  paywall + billing 3g · storage connectors 3h · grocery engine +
  serving-rescale 4a · cap counter 4d ($2.99 top-up UNCONFIRMED, behind
  kTopUpEnabled) · link door (D9, blogs-only; also: empty-state link caption
  + sheet link row omitted until then) · manual entry ("type it in by hand").
- Cover-image crop tier 2 (bbox from same extraction call) — spike-gated;
  tier 1 (BoxFit.cover) SHIPPED at skin time as planned.
- Snap-a-page "handwriting welcome": promise UNTESTED — spike before listing
  copy (D9 flag). The camera row exists in the sheet; same pipeline.
- ADR 0001 (schema v1) — graduates on Gate-1 pass (now includes favorite).
- T2 landing page (live 2 Sep target).
