# T3 — mvp-build
goal: extract → save → list → open, installable alpha on closed track 2026-10-19
gate: builds ahead of Gates 1–2 under amended constraint 4 (context.md §4,
      2026-08-06) — gates still decide whether any of this SHIPS
opened: pulled forward 2026-08-06 (originally 21 Sep) · status: engine slice DONE
        through bare UI (77 tests green); app installed + launched on the S21
division: Arnar owns UI/design (sketches after festival); agent owns the engine.
          Skins replace widgets and colors, never flows (editable review, delete,
          reorder are load-bearing — architecture review 2026-08-06).
design:   skin spec = docs/design/handoff.md (full token→Flutter spec, imported
          2026-08-06 from Arnar's Claude Design project) + docs/design/*.png +
          review-notes.md catches. As-built map with all deviations:
          docs/design/skin-implementation-map.md. Alpha skin BUILT 2026-08-06: 3a import sheet ·
          3c review · 3d cookbook · 3e detail (+4b empty, 4c failed) + cook mode
          3f (pure view, wired). Post-alpha screens ALSO BUILT as previews behind
          the debug dev gallery (long-press wordmark): batch 3b · paywall 3g ·
          storage 3h · grocery 4a · cap 4d — wire when engines land.
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
  recovery = rotate key, rebuild, minutes. · 2026-08-06 infra round: dev key's
  project is now TIER 3 POSTPAY (leak = money, hence daily quota cap + billing
  alert in pulse queue). Proxy HOME direction: Cloud Run in the same GCP project
  as the Gemini API (Arnar offered org+project, dissolving his earlier no-GCP)
  — service-identity auth replaces the storable key entirely. Build timing
  unchanged: post-alpha, before 11 Dec.
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
- D10 monetization shape (2026-08-06 hyperfocus round; Arnar delegated the call
  to the agent's marketing recommendation): free taste = 3 imports, LIFETIME,
  never resets. Why: the aha must happen on the buyer's OWN screenshot —
  "rescue YOUR camera roll" is personal, a demo recipe isn't — and a
  non-resetting taste is the anti-pattern to ReciMe's resetting free tier,
  the category's loudest complaint (report §2.2). After 3: hard wall
  (constraint 2), one-time unlock. Price anchor ~$25 (Crouton ships AI import
  at $24.99 one-time, §6.2); FINAL price = T4 decision; the landing page
  STATES the price so Gate 2 measures price-aware demand. Implementation:
  D7's per-install proxy counter doubles as the trial counter (installs start
  with 3; purchase raises to the fair-use cap) + on-device gate for UI.
  Accepted leak: reinstall resets the on-device taste (~3¢ exposure) — a
  reinstall-grinder was never a buyer. Listing copy: "Try 3 free. Pay once.
  Yours forever."

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
- SKIN DONE 2026-08-06 (late night): DittoDatto tokens → lib/ui/theme.dart
  (light "Stitch Slate" + dark "Midnight", both ship, themeMode system) ·
  shared primitives lib/ui/widgets/skin.dart (TokenCard, chips, glass, gradient
  FAB, striped placeholder, qty-bold, originals viewer) · fonts BUNDLED as
  assets (app/google_fonts/, OFL licenses registered) — offline-correct and
  test-safe (technical rule 8). Schema v1 + favorite bool (T1 D1 amendment;
  serialized only when true → old files round-trip byte-identical). Review-note
  catches honored: delete-toggle OMITTED (engine can't delete originals yet),
  "On this phone" quiet pill, heart = tertiary moment. Covers = screenshot-1
  BoxFit.cover (tier 1 free, per parked two-tier idea). Verified: 77 tests
  green · analyze clean · APK installed + launched on S21, skin renders in
  dark mode with Arnar's real recipe.
- Known alpha edges (accepted): review flagged-line confirm chip is UI-state
  only · detail check-offs ephemeral · cook-mode timer is in-screen only ·
  link section absent from import sheet (D9 post-alpha).
- NOT done: share-sheet · SAF store · empty-state link caption (needs D9).

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
5. ✔ 2026-08-06 (late) — alpha skin: hi-fi 3a/3c/3d/3e (+4b/4c) wired on the
   proven flows, cook mode 3f wired, post-alpha 3b/3g/3h/4a/4d built as
   dev-gallery previews. 77 tests green, on the S21 same night.
6. BLITZ (agreed 2026-08-06 eve): night 1 share-sheet + SAF store (arch §8) →
   night 2 grocery engine + wire 4a → night 3 batch 3b + manual entry →
   night 4 settings + link door D9. IF the Play fee lands early (Arnar's
   offer: pay before the w/e on a strong Friday build) → billing/paywall 3g
   wiring joins, tested with license testers, D10 shape. Friday-midnight
   target = CLOSED-TEST-COMPLETE build — Google's 12-tester/14-day closed-test
   rule gates production regardless of build speed, and public sales stay
   behind Gates 1–2 either way. Festival 12–16 Aug = tester recruiting
   (QR to the opt-in link; 12 opted-in testers required).
7. Alongside: Arnar's visual pass (12 screens, light+dark); T1 D5 in-app
   arm-A y/n run feeds Gate 1 (see T1 plan).

## Rollback / cleanup
Engine built ahead of gates: a failed Gate 1 or 2 archives app/ with the repo,
per context.md §Gates — sunk cost is agent-hours, accepted 2026-08-06.
