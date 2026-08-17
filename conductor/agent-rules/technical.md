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
3. On PlutoII, `cp` AND `rm` are shell-aliased to interactive mode — a scripted
   call hangs or silently no-ops on the prompt (cp broke a background build
   2026-08-06; rm left a "deleted" test file in place 2026-08-17). In scripts
   use `\cp -f` / `\rm -f` or write via redirection.
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
7. All persisted JSON/text writes go through lib/data/atomic_file.dart
   writeStringAtomic — never hand-roll tmp+rename (5 copies had drifted by
   2026-08-09; AppSettings had none and risked the SAF grant). The exact
   `<path>.tmp` suffix is LOAD-BEARING: res/xml backup rules enumerate it and
   delete paths sweep it — changing the naming means changing both.
8. Widget tests settle real IO in rounds (runAsync+pump per hop) — adding IO
   hops to a persisted write path (flush, rename) needs the affected tests'
   `rounds:` budget raised, or they fail as "state didn't persist"
   (settings_tab_test, 2026-08-09). Count the awaits, not the wall time.
9. Google's Android OAuth clients bind package name + signing-cert SHA-1
   (2026-08-09: the debug→upload signing flip broke Drive auth on-device;
   Dropbox PKCE checks no cert and kept working). Every signing cert needs
   its own Android client entry in the GCP console — debug, upload, and the
   Play App Signing cert at first Play upload. ADD clients, never replace:
   replacing kills auth for the other build flavor. Extract a SHA-1 with:
   keytool -list -v -keystore <jks> -storepass <pw> | grep SHA1
10. Google OAuth for installed Android apps REQUIRES the redirect scheme to
    be the reversed client id (com.googleusercontent.apps.<id>); a
    package-name scheme 400s invalid_request even with the client's "Enable
    custom URI scheme" box ticked (S21, 2026-08-09). Client-id swap =
    manifest <data> entry swap too — the scheme is derived in oauth.dart but
    the intent-filter is static. Dropbox has no such rule (byte-exact
    console-registered redirect).
11. EVERY device build must carry the keys: `flutter build apk --release
    --dart-define-from-file=dev.env` (same flag for `flutter run`). A plain
    build compiles the OAuth client ids in as `placeholder-*`, and the app
    reports it honestly as "awaiting keys in this build" on the storage
    screen — which reads like a regression in Drive/Dropbox, not like a
    build mistake (Hermes shipped one to the S21, 2026-08-10). Rule 6 says
    where the mirror lives; this one says the flag is never optional.
12. Remote (web) sessions run in a bare cloud container under a DIFFERENT
    path (/home/user/...) with NO Flutter SDK — install current stable via
    the releases_linux.json manifest before claiming any test result. A
    newer SDK than the repo's rewrites app/analysis_options.yaml (analyzer
    excludes) and app/pubspec.lock (SDK-pinned transitives) on every
    pub get/analyze/test — `git checkout --` both before committing so the
    diff stays the feature (Hermes, remote session 2026-08-15).
13. Suite flakes ≠ broken change: the real-IO settle() tests (grocery_flow
    first) starve under parallel test isolates on a loaded machine — the
    clean tree flakes identically. Verify with `flutter test --concurrency=1`
    before blaming the diff. Corollary: one settle round advances ~ONE real-
    IO step, and the atomic write chain (mkdir → write tmp → flush → rename)
    needs the full default rounds — a 4-round settle lost the persistence
    write entirely (cookbook_view test, 2026-08-15).
14. testWidgets bodies run under fake-async: ANY real IO started outside
    `tester.runAsync` (a File write/read in the test body, not just the app's
    writes) never completes — the test HANGS silently, presenting as an empty
    output file + a killed timeout, not a failure. Wrap every direct file op
    in runAsync; the settle() helper only advances IO that runAsync started
    (cover_flow test hang, 2026-08-17).
15. Android debug keystores are PER-HOST (~/.android/debug.keystore): an APK
    installed from another environment (remote container, other machine)
    blocks `adb install -r` with INSTALL_FAILED_UPDATE_INCOMPATIBLE. Only fix
    is uninstall, which WIPES app data — warn first, get the yes. Same-host
    rebuilds thereafter keep data (S21, 2026-08-17). Kin to rule 9's
    cert-binding: signature identity, different layer.
16. External-lookup failures masquerade as not-found (OFF shell spike,
    2026-08-17: throttled requests printed MISS; same barcodes HIT on rerun).
    Any lookup client models THREE outcomes — FOUND / NOT_FOUND only on the
    API's explicit negative ("status":0) / UNAVAILABLE for everything else —
    and retries only UNAVAILABLE. OffClient's sealed result is the pattern;
    the UI must show the two negatives differently. OFF also requires an
    identifying User-Agent.
17. FileImage caches by PATH: overwriting an image file in place (product
    photo replace, jpg→jpg) keeps rendering the old bytes until
    `FileImage(file).evict()`. Any same-path image overwrite needs the evict;
    recipe covers dodged it only because the jpg↔png swap changes the path
    (2026-08-17).
18. A flag that renames a nav surface breaks every test that FINDS it by
    label — kPantryEnabled relabelled slot 2 'Unlock'→'Pantry' and two
    shell_test cases failed two sessions later, misattributed to the next
    agent's diff. Tests that tap a flag-owned surface derive the label from
    the flags (shell_test's kSlot2Label) instead of hardcoding it. Corollary
    proven the same night: a subagent's "pre-existing failure" claim is a
    HYPOTHESIS — verify against the base commit before accepting it; this
    one was our own earlier change (2026-08-17).
19. Adding a directory to the sync layout is a DELETE-SAFETY change, not a
    feature: sync_source.safeName is a strict whitelist of exact shapes and
    sync_engine._ownedName gates delete propagation to those same shapes.
    Two invariants must be tested when extending it (pantry/, 2026-08-17):
    an OLD manifest can never contain the new names (so they can never read
    as vanished→delete), and an OLD client meeting the new remote dir drops
    it from tracking rather than deleting it. Data migrations into the
    user's folder go copy → read-back-VERIFY → delete, remove the source dir
    only when empty, and carry no done-flag — a drained dir is the flag, so
    an interrupted run resumes.
