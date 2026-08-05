# T3 — mvp-build
goal: extract → save → list → open, installable alpha on closed track 2026-10-19
gate: builds ahead of Gates 1–2 under amended constraint 4 (context.md §4,
      2026-08-06) — gates still decide whether any of this SHIPS
opened: pulled forward 2026-08-06 (originally 21 Sep) · status: engine slice started
division: Arnar owns UI/design (sketches after festival); agent owns the engine.
          Skins replace widgets and colors, never flows (editable review, delete,
          reorder are load-bearing — architecture review 2026-08-06).
architecture: docs/architecture-draft.md v2 — P1–P7 + telemetry go to /grill
              BEFORE further building (agreed 2026-08-06).

## Decisions
- D1 applicationId: com.merkurialstudio.myrecibook — Arnar chose 2026-08-06;
  Play-permanent once uploaded.
- D2 dev extraction key via --dart-define=GEMINI_API_KEY (arch P5); proxy swap
  post-alpha if P5 survives the grill.

## State (2026-08-06 checkpoint)
- app/ scaffold (Flutter 3.44, Android-only) · deps: http, image_picker, uuid,
  path_provider · assets: structure_prompt.md + recipe.schema.json.
- Done, `flutter analyze` clean: lib/domain (recipe model = schema v1, validator,
  Extractor interface) · lib/data (GeminiExtractor arm A, LocalFolderStore —
  hostile-folder-safe listAll, save validates + copies images, delete removes both).
- NOT done: tests · UI screens · share-sheet · SAF store impl · device run.

## Steps
1. /grill architecture P1–P7 + telemetry; fold verdicts here and into the draft.
2. Tests: round-trip semantic equality (fixture from spike example), validator cases.
3. Bare UI: list / import→review(editable) / detail(+delete, notes). Flows only —
   skin comes from Arnar's post-festival sketches.
4. Device run on S21 with dev key (--dart-define): first real end-to-end import.
5. Then per grill verdicts: share-sheet plumbing, SAF store (arch §8 budgets).

## Rollback / cleanup
Engine built ahead of gates: a failed Gate 1 or 2 archives app/ with the repo,
per context.md §Gates — sunk cost is agent-hours, accepted 2026-08-06.
