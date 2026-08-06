# T3 — mvp-build
goal: extract → save → list → open, installable alpha on closed track 2026-10-19
gate: builds ahead of Gates 1–2 under amended constraint 4 (context.md §4,
      2026-08-06) — gates still decide whether any of this SHIPS
opened: pulled forward 2026-08-06 (originally 21 Sep) · status: engine slice DONE
        through bare UI (77 tests green); app installed + launched on the S21
division: Arnar owns UI/design (sketches after festival); agent owns the engine.
          Skins replace widgets and colors, never flows (editable review, delete,
          reorder are load-bearing — architecture review 2026-08-06).
design:   skin spec = docs/design/*.png (Arnar, 2026-08-06 — arrived early).
          Alpha skin targets: 1a review · 1b cookbook · 1c detail · 2a
          single-recipe import path. Post-alpha with designs READY: batch queue
          2b · cook mode 1d · paywall 1e · storage setup 1f · camera-roll cleanup
          nudge · serving-rescale→grocery.
architecture: docs/architecture-draft.md v2 — GRILLED 2026-08-06 (cowork session):
              all 8 proposals agreed → D2–D8 below. Draft §9 maps P# → D#.

## Decisions
- D1 applicationId: com.merkurialstudio.myrecibook — Arnar chose 2026-08-06;
  Play-permanent once uploaded.
- D2 (P5, grilled 2026-08-06) proxy deferred to post-alpha: the closed track calls
  the model directly with a restricted, quota-capped dev key via
  --dart-define=GEMINI_API_KEY behind a compile-time flag. Frozen request shape
  keeps the proxy swap ~1 h of client work; the proxy MUST exist before the 11 Dec
  production release. Accepted risk: a leaked closed-track APK burns capped quota —
  recovery = rotate key, rebuild, minutes.
- D3 (P3, 2026-08-06) state = ChangeNotifier + Provider only. Boring on purpose;
  revisit only on real pain — migrating four screens later is days, not weeks.
- D4 (P1, 2026-08-06) list index = rescan the folder each app session; NO persisted
  cache in alpha. Add a cache file when a real library nears ~100 recipes, using
  scan times measured on the S21 — the trigger is evidence, not a guess.
- D5 (P4, 2026-08-06) inbox strip CUT from alpha: failed imports show a plain
  "failed → retry" on the cached copy (~2 h of UI vs up to 2 nights). Inbox =
  post-alpha polish.
- D6 (P6, 2026-08-06) editing scope v1: pre-save review edits = title + any raw
  line; post-save = notes only; full structured editing is post-alpha. Backstop:
  delete + re-import (duplicates accepted in v1).
- D7 (P2, 2026-08-06) fair-use cap machinery: static shared secret + install_id
  frozen into the request shape from day one; the per-install counter lives in the
  proxy — constraint 3 amended to allow exactly that state (context.md §3).
  Play Integrity only if real abuse appears.
- D8 (telemetry, 2026-08-06) none in alpha — no crash/analytics SDK. Play vitals +
  12 named testers cover the closed test. Revisit at production as its own decision.
- D9 (2026-08-06, decided on Arnar's mockups) link-import door = post-alpha BONUS,
  blogs only: read the schema.org/Recipe JSON-LD food blogs already publish; a
  clean parse costs NO AI rescue (never touches the cap). Social links (TikTok/IG)
  are NOT fetched — honest redirect: "screenshot the caption — that always works"
  (report §6.5 droppable-bonus framing; §5 treadmill 1 avoided). ~2–3 nights when
  its turn comes. Flag: "handwriting welcome" (Snap-a-page) is an UNTESTED promise
  — must pass a spike test before it appears in any listing copy.

## State (2026-08-06 night checkpoint)
- app/ (Flutter 3.44, Android-only) · deps: + provider (D3) · analyze clean,
  77 tests green (domain round-trips vs spike goldens, validator, store hostile-
  folder + confinement, extractor over MockClient, UI flows on temp dirs).
- lib/ui built (flows only, default Material 3 — skin comes from docs/design):
  LibraryModel (D3/D4) · list (rescan, skipped footer, FAB) · import review
  (spinner→failed+Retry (D5)→editable title+raw lines (D6), <0.8/needs_review
  flags, no-steps banner + add-screenshot re-extract) · detail (notes-only edit,
  confirm delete).
- Review hardening 2026-08-06: transport failures all map to retryable
  ExtractionException; store confines ids/image paths to the recipe folder;
  UTF-8 bodyBytes decode (technical rule 6); load() null on corrupt (§7).
- Debug APK (dev key baked) installed + launched clean on S21 (Android 15).
  VS Code launch.json → "MyReciBook (S21, dev key)" via app/dev.env.
- Real end-to-end import PASSED on S21 2026-08-06 (incl. add-screenshot flow).
- NOT done: share-sheet · SAF store · skin.

## Steps
1. ✔ 2026-08-06 — /grill done (cowork): 8/8 agreed → D2–D8; draft §9 + context.md
   §3 + T1 plan updated.
2. ✔ 2026-08-06 — tests: 77 green; spike outputs promoted to test/fixtures/
   goldens (P7); adversarial review closed 7 confirmed findings.
3. ✔ 2026-08-06 — bare UI: list / import→review(editable) / detail(+delete,
   notes). Flows only — skin spec: docs/design/*.png.
4. ✔ 2026-08-06 — device run PASSED (Arnar, real recipe): extract → edit → save,
   including the add-screenshot re-extract pulling in the method. His words:
   "comes out pretty well for the bare ui".
5. Then per grill verdicts: share-sheet plumbing, SAF store (arch §8 budgets),
   alpha skin (1a/1b/1c/2a per §design).

## Rollback / cleanup
Engine built ahead of gates: a failed Gate 1 or 2 archives app/ with the repo,
per context.md §Gates — sunk cost is agent-hours, accepted 2026-08-06.
