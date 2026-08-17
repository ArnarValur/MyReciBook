# T3 — mvp-build
goal: extract → save → list → open, installable alpha on closed track 2026-10-19
gate: builds ahead of Gates 1–2 under amended constraint 4 (context.md §4,
      2026-08-06) — gates still decide whether any of this SHIPS
opened: pulled forward 2026-08-06 (originally 21 Sep) · status: senior review
        CLOSED 2026-08-09 (all findings fixed, strict analyzers);
        upload-key build live on the S21 — Arnar's round 2 PROVED camera-photo
        extraction, screenshots and Dropbox connect+sync on-device; Drive
        needed TWO fixes (upload-SHA-1 client in console + reversed-client-id
        redirect, tech rules 9-10) — installed, retry pending; F5 conflict
        fence + D2 proxy code built. 2026-08-15 (remote, folded to main):
        queue tab retired — slot 2 = Unlock tab (3g pitch promoted from the
        dev gallery, billing seam awaits 3g; queue = pushed route + Cookbook
        strip) — and Cookbook grid ⇄ list toggle (CookbookPrefs). 2026-08-17:
        fresh dev.env build on the S21 — Arnar's pass on both surfaces GOOD,
        DRIVE SMOKE PASSED (both connectors now proven on-device); Unlock
        why-card made static (his call); cover STORE tests in (350 on paper),
        cover UI-tap tests dropped (his call — gap accepted, stays closed)
division: Arnar owns UI/design (sketches after festival); agent owns the engine.
          Skins replace widgets and colors, never flows (editable review, delete,
          reorder are load-bearing — architecture review 2026-08-06).
design:   skin spec = docs/design/handoff.md (full token→Flutter spec, imported
          2026-08-06 from Arnar's Claude Design project) + docs/design/*.png +
          review-notes.md catches. As-built map with all deviations:
          docs/design/skin-implementation-map.md. Alpha skin BUILT 2026-08-06: 3a import sheet ·
          3c review · 3d cookbook · 3e detail (+4b empty, 4c failed) + cook mode
          3f (pure view, wired). Post-alpha screens ALSO BUILT as previews behind
          the debug dev gallery (long-press wordmark): batch 3b · storage 3h ·
          grocery 4a · cap 4d — wire when engines land. Paywall 3g PROMOTED
          2026-08-15 to the live Unlock tab (ui/unlock_tab.dart, shared
          PaywallPitch; the gallery preview keeps the modal form).
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
  unchanged: post-alpha, before 11 Dec. · 2026-08-09: proxy BUILT AHEAD
  (proxy/ — Dart shelf relay, key server-side as header, model allowlist,
  per-install monthly cap strawman, 10 tests; Cloud Run runbook in
  proxy/README.md) and the client swap is DONE (EXTRACTION_PROXY_URL define +
  X-Install-Id from install_id.dart; no define = direct-key dev mode). Only
  the DEPLOY remains — Arnar's gcloud/billing call, deadline unchanged.
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
  delete + re-import (duplicates accepted in v1). · AMENDED 2026-08-06 night
  (Arnar): post-save edit = reopen the saved recipe in the review screen, save
  back — notes-only too thin in real use; full structured editor still post-alpha.
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
- D11 (2026-08-10, Arnar's call on his own hands-on) covers are USER-CHOSEN,
  never auto-promoted from a screenshot. A screenshot cover "comes out ugly",
  and the grid is the first thing a buyer sees. No-cover renders a drawn tile
  (brand gradient keyed off the title + logo watermark), so the app is never
  ugly by default and never needs an image it doesn't have. Costs a schema
  addition — top-level `cover`, absent unless set, pointing either at
  images/<id>-cover.<ext> (their photo, copied into their folder so it syncs
  and survives reinstall) or at one of source.original_images (no second copy
  of bytes already there). File-format change = hard to reverse, hence a
  D-number; supersedes the "covers = screenshot-1 BoxFit.cover" tier-1 note
  in the 2026-08-06 State below. Auto-crop tier 2 and AI covers stay parked.

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
- RUN COMPLETE (2026-08-06 night, commits be855dd…9ef7b81): SAF document-tree
  store (pick-once grant, re-pick flow, migration) + share-sheet intake ·
  grocery engine (§6.3: merge, aliases, category memory) + 4a + glass NavBar
  shell + 5c drawer · saved-recipe edit via review (D6 am.; updateRecipeOnList
  hardened to preserve checked/staple state) · storage connect 3h full on
  placeholder creds (PKCE, Drive/Dropbox remotes, manifest-diffed mirror-up +
  additive restore) · batch 3b (sequential, auto-save high-confidence) +
  manual entry (source.type 'manual', no cap) · settings minimal. 309 tests,
  analyze clean, each item adversarially reviewed + installed on the S21.
  ~15 DEVIATION flags in app/ mark undesigned surfaces for Arnar's design turn.
- TURN 6 IN CODE (2026-08-06 dawn, 00937bb): settings 6a (segmented theme,
  truthful storage row, version-only footer until receipt — drawer matched) ·
  storage manage 6e (supersedes 3h post-setup; remotes restructured to make
  MyReciBook/recipes true) · 6f canonical destructive confirm (shared widget,
  recipe delete migrated). Ratified DEVIATION flags retired. 313 tests.
- CREDS WIRED (2026-08-06, Arnar's console pass): DRIVE_CLIENT_ID +
  DROPBOX_APP_KEY in .env → app/dev.env (technical rule 6 sed mirror). Both
  connectors leave the `placeholder-*` branch together; Dropbox app is Scoped/
  App-folder with PKCE public clients ALLOW, Drive is an Android client on the
  debug SHA-1 (values in pulse). UNPROVEN on device — no connect/sync run yet.
- HANDS-ON ROUND 1 (2026-08-06, Arnar on the creds-live build): 7 findings →
  fixed same session. Founder decisions with Arnar: 5c drawer REMOVED
  (app_drawer.dart deleted; utility → Settings rows) · bar slot 3 = Import
  queue (embedded BatchQueueScreen; Plan behind kMealPlanEnabled) ·
  change-folder → system picker directly (BootGate: appNavigatorKey for
  ready-phase dialogs, KeyedSubtree(treeUri) remount — technical rules 11–12) ·
  collapsing hero on detail · grocery swipe-delete + Clear all (6f, snapshot
  undo — technical rule 13) · Favorites-only chips · flags home =
  app/lib/features.dart (behavioral 19). 315 tests. Latest APK built,
  NOT installed (S21 unplugged).
- Turn-7 design queue: ~~cover-image picker~~ SHIPPED 2026-08-10 (D11) ·
  ratify drawer removal + bar reshape + collapsing hero · manual entry ·
  edit copy · batch edges.
- BRAND + COVERS SHIPPED (2026-08-10): Arnar's logo pack
  (docs/MyReciBook-logo/assets/logo/) is the authority; app/android res carries
  an adaptive icon (vector foreground doubling as the Android 13 monochrome
  layer, evenOdd spine knockout) + regenerated legacy PNGs, and
  app/lib/ui/widgets/logo_mark.dart draws the same paths in-app for the header
  (full mark) and the Cookbook tab (book only — the steam is mush at 22dp).
  Cover picker per D11 lives on the detail hero as the 'add cover' pill.
  Cover-flow gap CLOSED 2026-08-17 at the store layer (6 tests: copy-in,
  ext-swap cleanup, remove-takes-bytes, promote=ref, delete-takes-cover,
  edit-keeps-cover); UI tap choreography deliberately untested (Arnar's
  call, 2026-08-17 — do not re-queue, behavioral 16).
- NOT done: billing 3g (behind fee) · D9 empty-state link caption ·
  on-device storage smoke (runbook Part C) · latest-APK install.

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
6. ✔ 2026-08-06 (night→dawn) — NO-LIMITS RUN COMPLETE, all 6 items, green
   after each (detail in State above). Billing/paywall 3g still JOINS the
   moment the Play fee exists (Arnar's call — his strong-build bar is now met
   in code, verdict needs his hands-on pass). D9 link door stays post-alpha.
   Google's 12-tester/14-day closed-test rule still gates production.
7. Alongside: Arnar's visual pass (12 screens, light+dark); T1 D5 in-app
   arm-A y/n run feeds Gate 1 (see T1 plan).

## Rollback / cleanup
Engine built ahead of gates: a failed Gate 1 or 2 archives app/ with the repo,
per context.md §Gates — sunk cost is agent-hours, accepted 2026-08-06.
