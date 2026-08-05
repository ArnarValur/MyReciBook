# Pulse — MyReciBook
*State only. REWRITTEN at every checkpoint, never appended. Cap 60 lines.*

## 📍 Now
- Phase: pre-project (kickoff 2026-08-20); constraint 4 amended — building
  unblocked, gates decide ship/stop (context.md §4).
- Architecture SETTLED 2026-08-06: /grill closed all 8 proposals in a cowork
  session (~40 min, three recommend-first rounds, all agreed as recommended)
  → T3 D2–D8 · T1 graduation gains fixtures · constraint 3 amended ("stateless
  except the cap counter", context.md §3). Draft §9 is the P#→D# map.
  Engine now builds on settled ground.
- Division of labor: Arnar owns UI/design (sketches after festival ~mid-Aug);
  agent owns the engine. Skins replace widgets, never flows.
- Teach-while-building GRADUATED to behavioral rule 14 (explicit yes 2026-08-06):
  plain-words explainers before jargon, visual maps for decisions. Two-folders
  model (Gallery = input; SAF recipe folder = owned output) cleared real confusion.
- T1 smoke PASSED 2026-08-06: 2 real recipes (2 screenshots each, ads, dark
  mode) → clean JSON, arm A, gemini-3.6-flash, free tier. No hallucinated steps.
- Schema v1: source.original_images is an ARRAY; extraction.mode enum image|ocr_text.
- app/ engine slice LEAPT AHEAD (live Code session, 2026-08-06, committed in
  f05d8c5): domain + data + bare UI (list / import-review / detail) + 4 test
  suites + spike fixtures (P7 realized). UNVERIFIED here — no Flutter in the
  Cowork sandbox; Code session must `flutter test` + analyze before more building.
- Design set arrived EARLY 2026-08-06 (mid-festival bonus): 8 screens →
  docs/design/*.png = the skin spec; several solved open UX questions (pairing
  toggle, flagged-only review, provenance flip). D9: link door = blogs-only
  JSON-LD, post-alpha; social links → honest screenshot redirect.
- Gemini free-tier key in .env (gitignored); dev key via --dart-define (T3 D2).
- ocr_dump APK built → spike/out/ocr_dump.apk (gitignored, on disk) — arm B ready
  for S21 whenever USB is convenient.

## 🚀 Active tracks
- T1 extraction-spike — smoke passed; needs 6 more honest screenshots (English
  web/social — NO Icelandic framing) + arm B run. Plan: conductor/tracks/T1-…/plan.md
- T3 mvp-build — grilled; engine slice continues (tests are next).
  Plan: conductor/tracks/T3-mvp-build/plan.md

## ⚠️ Blockers
- Play Console fee: Arnar pays AFTER the festival (next week); registration still
  20 Aug morning. Any review snag hits the 19 Oct alpha chain.
- ~~Sandbox git locks~~ RESOLVED 2026-08-06: the sandbox can now self-clean via
  Cowork's delete permission (rule 12 updated). No cleanup one-liner needed.

## 📋 Next queue
1. Verify the engine slice (Claude Code session): `flutter test` + analyze —
   tests/UI/fixtures are already written (f05d8c5). Then device run on S21
   with dev key (--dart-define): first real end-to-end import.
2. Arnar (~20 min): 6 more honest screenshots → spike/screenshots/, pairs as
   name-1/name-2 — completes the Gate-1 test set.
3. Arm B on S21: install spike/out/ocr_dump.apk, OCR the set, adb pull dumps,
   harness --mode text → fill results.md y/n → Gate 1 verdict (due 30 Aug).
4. 20 Aug 09:00 (scheduled): kickoff — Play Console registration + spike status.

## 📌 Parked
- Post-alpha scope (designs ready for most, T3 plan §design): paywall 1e · sync
  connectors 1f · grocery engine + serving-rescale · inbox/batch queue (D5, 2b) ·
  full editing (D6) · proxy build (D2, MUST land before 11 Dec) · link door
  (D9, blogs-only) · cook mode 1d · camera-roll auto-scan + cleanup nudge · polish.
- Snap-a-page "handwriting welcome": UNTESTED promise — spike-test grandma's card
  before any listing copy (D9 flag).
- ADR 0001 (schema v1) — graduates on Gate-1 pass; fold the constraint-3
  amendment story in when it does.
- T2 landing page (live 2 Sep target).
- SAF store impl + share-sheet plumbing (arch §8 budgets; build wk 1–2).
