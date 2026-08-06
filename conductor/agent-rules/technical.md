# Technical rules — graduated lessons
*Appended automatically at checkpoint when a technical lesson repeats-proofs itself.*

1. Model names drift (spike hit a dead `gemini-2.5-flash` on a fresh key,
   2026-08-06). Never trust a hardcoded model id: enumerate live via the
   provider's ListModels endpoint, keep `--model`/constructor overrides in every
   client. Current names live in code defaults only, never in conductor docs.
2. LLMs fill envelope fields with plausible garbage (invented `extraction.model`
   "gpt-4o" + fake timestamp, 2026-08-06). Metadata about an extraction — model,
   mode, timestamps, ids, paths — is stamped by our code after parsing, never
   requested from or trusted to the model.
3. On PlutoII, `cp` is shell-aliased to interactive mode — a scripted `cp` hangs
   on the overwrite prompt (broke a background build, 2026-08-06). In scripts use
   `\cp -f` or write via redirection.
4. Free-tier Gemini 503s ("high demand") are transient — retry with ~45 s backoff
   succeeded on the first retry (2026-08-06). Build retry-with-backoff into any
   free-tier caller; don't debug a 503.
5. Cowork and Claude Code sessions can be LIVE on the same working tree at once
   (f05d8c5, 2026-08-06: a Cowork `git add -A` swept the Code session's entire
   in-flight engine slice into an unrelated design commit; both sessions then
   graduated this rule independently — merged here). Before staging anything:
   `git status --short` and READ it — foreign changes mean a sibling session is
   active. Stage explicit paths only; never `add -A`, never reset/rebase/amend
   while a sibling may hold the index. At checkpoint: check `git log` since
   session start BEFORE writing conductor files; reconcile the sibling's
   pulse/relay edits, never clobber.
6. `--dart-define-from-file` cannot parse shell-style `export KEY=...` (root
   .env is shell-sourced by the spike harness). Device/IDE builds read the
   gitignored mirror app/dev.env — regenerate on key rotation with:
   `sed -E 's/^export //' .env > app/dev.env` (2026-08-06).
7. package:http decodes `resp.body` as latin1 when the response omits a charset
   → ½/⅓/é mojibake in recipe text. Always
   `utf8.decode(resp.bodyBytes, allowMalformed: true)`; pinned by extractor
   test. Applies to the future proxy client too (2026-08-06).
8. google_fonts fetches fonts at runtime and RETHROWS fetch failures — in
   widget tests that fails whatever test is pumping. Fonts live as bundled
   assets (app/google_fonts/ + pubspec `- google_fonts/`) and
   test/flutter_test_config.dart pins `allowRuntimeFetching = false`; keep both
   when adding font weights. Bundling is also product-correct: a kitchen app
   must not need network for its own type (2026-08-06). Related: the widget
   tests' `settle(rounds:)` helper counts real-IO awaits — asset font loads and
   Image.file decodes consume rounds, so new async UI work may need the number
   raised, and snackbar assertions need a SHORT settle (4s snackbar dies within
   a full one).
9. Claude Design exports (docs/*.html, ~8MB) are HTML wrapping JS-escaped
   string payloads — complex raw greps hang past the 120s timeout. Unescape
   first (python3, json-style \" \n replacement), then text-search screen ids
   in chunks. Screen annotations and exact copy live in those payloads
   (2026-08-06 night).
10. OAuth console downloads: an Android client's `client_secret_*.json` holds
    NO secret (client id + project id only — Android clients authenticate by
    package name + SHA-1, and PKCE covers the rest). Harmless, but never park
    console downloads in conductor/ — checkpoint commits that directory
    wholesale (behavioral 18). Gitignored as `client_secret_*.json`; the live
    values belong in .env → app/dev.env via the rule-6 sed mirror
    (2026-08-06).
11. Never share one GlobalKey<NavigatorState> between BootGate's gate
    MaterialApp and the ready-phase app's — the swap reparents the Navigator
    element and wedges the handoff. Keep two keys; BootGate takes the app's
    key as appNavigatorKey purely for phase-aware dialog context
    (_dialogContext) (2026-08-06).
12. Providers capture their store at create — any path that swaps the
    SafFolderStore without unmounting the app subtree MUST remount it
    (KeyedSubtree keyed by treeUri in BootGate.build). The old gate detour
    did this by accident; the direct-picker path does it on purpose. Regression
    shape: library shows the OLD folder after a switch (2026-08-06).
13. Undo snackbars: snapshot state first, fire the mutation without awaiting,
    show the bar with removeCurrentSnackBar (instant) — never await the
    persist and never queue behind a stale toast's exit animation. In widget
    tests, a Dismissible's slide+resize needs ~10 settle rounds before the
    bar is assertable (2026-08-06).
