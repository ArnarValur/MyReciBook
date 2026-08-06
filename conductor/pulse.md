# Pulse — MyReciBook
*State only. REWRITTEN at every checkpoint, never appended. Cap 60 lines.*

## 📍 Now
- Phase: pre-project (kickoff 2026-08-20); constraint 4 amended — building
  unblocked, gates decide ship/stop (context.md §4).
- Engine slice BUILT + ON DEVICE 2026-08-06 night: 77 tests green (spike outputs
  = golden fixtures, P7) + bare UI (list / import→review-edit / detail+notes+
  delete, D3–D6) + debug APK with dev key installed and launched clean on the
  S21. 15-agent workflow: 3-lens adversarial review, 11 findings → 7 confirmed
  → all fixed (stuck spinner, transport retries, path confinement, ½-mojibake,
  FAB double-tap, notes-save errors, test gaps). Arnar's REAL import PASSED
  same night, incl. add-screenshot re-extract pulling in the method.
- Design set arrived EARLY (pre-festival push — festival starts 12 Aug, guest
  arrives Sat 15; this week = Arnar's all-nighter window): 8 screens → docs/design/*.png =
  the skin spec; D9: link door = blogs-only JSON-LD, post-alpha; social → honest
  screenshot redirect. "Handwriting welcome" promise UNTESTED (D9 flag).
- Division of labor: Arnar owns skin (spec now in docs/design), agent owns
  engine. Skins replace widgets, never flows.
- Schema v1: original_images ARRAY; extraction.mode enum image|ocr_text.
  Known-accepted alpha edges: re-save orphans old images; copyWith can't null
  notes; 0-ingredient captures save (symmetric with no-steps retake flow).
- VS Code debug live: .vscode/launch.json → "MyReciBook (S21, dev key)"; key
  mirrors .env → gitignored app/dev.env (technical rule 5 has the regen line).
- Gemini free-tier key in .env; ocr_dump APK on disk (arm B ready).
- T1 smoke PASSED (arm A, gemini-3.6-flash): 2 multi-image recipes → clean JSON.

## 🚀 Active tracks
- T1 extraction-spike — smoke passed; needs 6 more honest screenshots (English
  web/social — NO Icelandic framing) + arm B run. Plan: conductor/tracks/T1-…/plan.md
- T3 mvp-build — engine slice done, real import PASSED on the S21; next session
  is UI-heavy (Arnar brings many screens/layouts) + share-sheet + SAF (arch §8).
  Plan: conductor/tracks/T3-mvp-build/plan.md

## ⚠️ Blockers
- Play Console fee: Arnar pays AFTER the festival (next week); registration still
  20 Aug morning. Any review snag hits the 19 Oct alpha chain.

## 📋 Next queue
1. Arnar (~20 min): 6 more honest screenshots → spike/screenshots/, pairs as
   name-1/name-2 — completes the Gate-1 test set.
2. Arm B on S21: install spike/out/ocr_dump.apk, OCR the set, adb pull dumps,
   harness --mode text → fill results.md y/n → Gate 1 verdict (due 30 Aug).
3. Agent next session: share-sheet plumbing + SAF store (arch §8 budgets), then
   alpha skin per docs/design (1a review · 1b cookbook · 1c detail · 2a import).
4. 20 Aug 09:00 (scheduled): kickoff — Play Console registration + spike status.

## 📌 Parked
- Post-alpha scope (designs ready for most, T3 plan §design): paywall 1e · sync
  connectors 1f · grocery engine + serving-rescale · inbox/batch queue (D5, 2b) ·
  full editing (D6) · proxy build (D2, MUST land before 11 Dec) · link door
  (D9, blogs-only) · cook mode 1d · camera-roll auto-scan + cleanup nudge · polish.
- Snap-a-page "handwriting welcome": UNTESTED promise — spike-test grandma's card
  before any listing copy (D9 flag).
- Cover-image crop (Arnar's idea 2026-08-06, noted not built): tier 1 free =
  cookbook card shows screenshot-1 BoxFit.cover at skin time; tier 2 = bbox from
  the SAME extraction call → crop to images/<id>-cover.jpg, nullable schema add —
  spike-test first (checkbox in results.md), ships only with tier-1 fallback.
- ADR 0001 (schema v1) — graduates on Gate-1 pass; fold the constraint-3
  amendment story in when it does.
- T2 landing page (live 2 Sep target).
