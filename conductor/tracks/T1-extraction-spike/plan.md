# T1 — extraction-spike
goal: prove screenshot → usable recipe JSON at Gate-1 quality
gate: GATE 1 (context.md) — verdict due Sun 2026-08-30
status: CLOSED 2026-08-06 — GATE 1 PASSED on Arnar's in-app judgment (his screenshots, his call, per D5); results ritual waived by Arnar. Arm B parked: tuning fallback only, no deadline.
verdict: PASSED, recorded on Arnar's report (stated across sessions). Do not re-queue recipe-collection or judging tasks — removed by Arnar 2026-08-06, for good.

## Decisions
- D1 recipe schema v1 — DRAFT at spike/recipe.schema.json. Design: `raw` always kept
  beside parsed fields (never destroy the user's text; grocery merging uses parsed,
  display falls back to raw) · per-item confidence drives the review screen ·
  `group` for "For the sauce:" sections · `schema_version` for future migration.
  → settle together before the spike; graduates to ADR 0001 on Gate-1 pass.
  · 2026-08-06 hi-fi review: + optional `favorite` boolean (user-owned state
  belongs in the user's file; `tags`/`notes` already existed). Code session:
  add to schema + validator + a fixture, keep it optional-absent-false.
- D2 structuring model — default: Gemini flash-class (free tier covers the whole
  spike, $0 — fits festival budget); OpenAI mini-class as B-provider. Model names
  drift, so the harness takes --model. The spike decides.
- D3 pipeline mode — the core experiment. Arms:
    A. image-direct (desktop, any evening) — quality upper bound
    B. mlkit-text (spike weekend, S21) — the real v1 pipeline
  If B ≈ A → ship B with image-retry fallback on low confidence (cheapest).
  If B ≪ A → ship image-direct and accept the cost (still pennies, report §4).
- D4 incomplete captures (agreed 2026-08-05, smoke-test finding) — when steps/fields
  are missing, the import screen detects it (`needs_review` + auto-checks) and asks
  the user to add another screenshot. The model must NOT deduce or invent missing
  content — faking mormor's steps breaks the "rescue YOUR recipe" promise. AI
  fill-in is post-alpha scope at best, its own decision if ever.
- D5 gate instrument (agreed 2026-08-06 eve) — arm A is judged THROUGH THE APP
  on the S21: the review screen makes the gate's wording ("usable without
  editing") concrete — judge y/n BEFORE touching an edit field. App-saved JSONs
  are the arm-A artifacts (pulled → spike/out/ next Code session). The desktop
  harness --mode image is demoted to prompt-tuning fallback, used only if the
  score lands under 9. Arm B unchanged — it tests the cheap pipeline the app
  deliberately doesn't carry yet. Unit fixed: recipes/rows, not screenshots.

## Steps
1. TONIGHT (~25 min, phone only): 8 more honest RECIPES from where recipes
   actually live — Instagram posts/stories, recipe sites, social media; English
   web/social framing; ugly ones welcome, no curating; pairs fine → 10 rows
   total. (Key set, 2 recipes + smoke already done 2026-08-05.)
2. TONIGHT (~40 min, phone only): arm A through the app (D5) — import each
   recipe via +, judge y/n at the review screen BEFORE editing, keep the tally.
   JSONs pulled into spike/out/ next Code session.
3. This w/e 8–9 Aug if the blitz holds (else Sat 22 Aug), ~1 h 10: copy the set
   → spike/screenshots/ as name-1/name-2 (~10 min — the harness pairs by
   filename), install spike/out/ocr_dump.apk (prebuilt, gitignored, on disk),
   OCR on-device, adb pull dumps, run arm B (--mode text).
4. Same weekend (~1–2 h): compare arms in out/results.md (app y/n column + arm
   B column), pick the winner per D3; tune worst prompt failures only if <9.
5. By Sun 30 Aug: Gate-1 verdict into pulse + relay (a scheduled session convenes
   this if it hasn't happened).

## Rollback / cleanup
spike/ is throwaway validation tooling — the app never imports it. On pass, THREE
artifacts graduate: schema + prompt (ADR 0001, app assets) + out/*.json as golden
test fixtures (P7 grilled 2026-08-06 — real model output becomes the app's
regression test data). On stop: archive per context.md §Gates.
