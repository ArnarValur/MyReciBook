# T1 — extraction-spike
goal: prove screenshot → usable recipe JSON at Gate-1 quality
gate: GATE 1 (context.md) — verdict due Sun 2026-08-30
deadline: spike w/e 2026-08-22/23 · budget: ~2 days · status: groundwork ready (2026-08-05)
verdict: made together on spike/out/results.md evidence — 9 of 10 "y" or stop

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

## Steps
1. Any evening pre-festival (~30 min, phone + laptop): 10 honest screenshots →
   spike/screenshots/ — from where recipes actually live: Instagram posts/stories,
   random recipe sites, social media; multi-screenshot recipes as name-1/name-2
   (agreed 2026-08-06: no Icelandic framing — sources are English web/social) ·
   free Gemini key from aistudio.google.com · smoke-run harness on 1 image.
   → Partially done 2026-08-05: key set, 4 screenshots (2 recipes), smoke PASSED.
2. Any evening (~1 h, optional bonus — pulls Gate 1 earlier): full arm-A run,
   skim out/*.json, tune structure_prompt.md, rerun.
3. Sat 22 Aug (~4 h, Claude Code on the Flutter-enabled host, S21 via USB):
   OCR the 10 screenshots on-device, adb pull the dumps, run arm B (--mode text).
   → APK prebuilt 2026-08-06: spike/out/ocr_dump.apk (gitignored, on disk) —
   step is now install + run, ~1 h.
4. Sun 23 Aug (~3 h): pick the winning arm, fix worst prompt failures, final run,
   fill the y/n column in out/results.md.
5. By Sun 30 Aug: Gate-1 verdict into pulse + relay (a scheduled session convenes
   this if it hasn't happened).

## Rollback / cleanup
spike/ is throwaway validation tooling — the app never imports it. On pass, THREE
artifacts graduate: schema + prompt (ADR 0001, app assets) + out/*.json as golden
test fixtures (P7 grilled 2026-08-06 — real model output becomes the app's
regression test data). On stop: archive per context.md §Gates.
