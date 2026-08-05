# Pulse — MyReciBook
*State only. REWRITTEN at every checkpoint, never appended. Cap 60 lines.*

## 📍 Now
- Phase: pre-project (kickoff 2026-08-20), but constraint 4 AMENDED 2026-08-06 at
  Arnar's direction: gates decide ship/stop, building is unblocked (context.md §4).
- Division of labor agreed: Arnar owns UI/design (sketches after festival ~mid-Aug);
  agent builds everything under the skin. Skins replace widgets, never flows.
- T1 smoke test PASSED 2026-08-06: 2 real recipes (2 screenshots each, ads, dark
  mode) → clean JSON, arm A, gemini-3.6-flash, free tier. No hallucinated steps.
- Architecture draft v2: docs/architecture-draft.md — 3-lens adversarial review,
  22 findings folded. Open proposals P1–P7 + telemetry = the /grill agenda.
- Schema v1 fixed while cheap: source.original_images now an ARRAY (was singular —
  unanimous review blocker); extraction.mode enum image|ocr_text.
- app/ scaffold live: com.merkurialstudio.myrecibook (locked, Play-permanent).
  Domain + data layers written, `flutter analyze` clean. No tests/UI yet.
- Gemini free-tier key in .env (gitignored). Dev key via --dart-define (P5).
- ocr_dump APK built → spike/out/ocr_dump.apk (gitignored, on disk) — arm B ready
  for S21 whenever USB is convenient.

## 🚀 Active tracks
- T1 extraction-spike — smoke passed; needs 6 more honest screenshots (English
  web/social — NO Icelandic framing) + arm B run. Plan: conductor/tracks/T1-…/plan.md
- T3 mvp-build — pulled forward; engine slice in progress.
  Plan: conductor/tracks/T3-mvp-build/plan.md

## ⚠️ Blockers
- Play Console fee: Arnar pays AFTER the festival (next week); registration still
  20 Aug morning. Any review snag hits the 19 Oct alpha chain.
- IDE reload ended the 2026-08-06 all-nighter session mid-build (checkpointed clean).

## 📋 Next queue
1. /grill on architecture draft P1–P7 + telemetry — BEFORE building further
   (agreed 2026-08-06). Then fold verdicts into the draft + track plans.
2. Engine slice remainder: tests (round-trip vs example fixture) · bare UI
   (list / import→review-edit / detail+delete) · run on device with dev key.
3. Arnar (~20 min): 6 more honest screenshots → spike/screenshots/, pairs as
   name-1/name-2 — completes the Gate-1 test set.
4. Arm B on S21: install spike/out/ocr_dump.apk, OCR the set, adb pull dumps,
   harness --mode text → fill results.md y/n → Gate 1 verdict (due 30 Aug).
5. 20 Aug 09:00 (scheduled): kickoff — Play Console registration + spike status.

## 📌 Parked
- Post-alpha scope (paywall, sync connectors, grocery engine, inbox strip, polish).
- ADR 0001 (schema v1) — graduates when Gate 1 passes.
- T2 landing page (live 2 Sep target) — untouched tonight.
- SAF document-tree store impl + share-sheet plumbing (budgeted: arch draft §8).
