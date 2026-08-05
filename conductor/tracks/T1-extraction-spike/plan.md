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
- D2 structuring model — default: Gemini flash-class (free tier covers the whole
  spike, $0 — fits festival budget); OpenAI mini-class as B-provider. Model names
  drift, so the harness takes --model. The spike decides.
- D3 pipeline mode — the core experiment. Arms:
    A. image-direct (desktop, any evening) — quality upper bound
    B. mlkit-text (spike weekend, S21) — the real v1 pipeline
  If B ≈ A → ship B with image-retry fallback on low confidence (cheapest).
  If B ≪ A → ship image-direct and accept the cost (still pennies, report §4).

## Steps
1. Any evening pre-festival (~30 min, phone + laptop): 10 honest screenshots →
   spike/screenshots/ (cropped ones, one handwritten, one Icelandic if real) ·
   free Gemini key from aistudio.google.com · smoke-run harness on 1 image.
2. Any evening (~1 h, optional bonus — pulls Gate 1 earlier): full arm-A run,
   skim out/*.json, tune structure_prompt.md, rerun.
3. Sat 22 Aug (~4 h, Claude Code on the Flutter-enabled host, S21 via USB):
   build ocr_dump from spike/ocr_dump_main.dart, OCR the 10 screenshots on-device,
   adb pull the dumps, run arm B (--mode text).
4. Sun 23 Aug (~3 h): pick the winning arm, fix worst prompt failures, final run,
   fill the y/n column in out/results.md.
5. By Sun 30 Aug: Gate-1 verdict into pulse + relay (a scheduled session convenes
   this if it hasn't happened).

## Rollback / cleanup
spike/ is throwaway validation tooling — the app never imports it. On pass: schema +
prompt graduate (ADR 0001, app assets). On stop: archive per context.md §Gates.
