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
   in-flight engine slice into an unrelated design commit). Before staging
   anything: `git status --short` and READ it — foreign changes mean a sibling
   session is active. Stage explicit paths only; never `add -A`, never
   reset/rebase/amend while a sibling may hold the index.
5. `--dart-define-from-file` cannot parse shell-style `export KEY=...` (root
   .env is shell-sourced by the spike harness). Device/IDE builds read the
   gitignored mirror app/dev.env — regenerate on key rotation with:
   `sed -E 's/^export //' .env > app/dev.env` (2026-08-06).
6. package:http decodes `resp.body` as latin1 when the response omits a charset
   → ½/⅓/é mojibake in recipe text. Always
   `utf8.decode(resp.bodyBytes, allowMalformed: true)`; pinned by extractor
   test. Applies to the future proxy client too (2026-08-06).
7. Parallel agent sessions on this repo are real: the design-drop session
   committed mid-engine-build (f05d8c5) and swept uncommitted work into its
   message. At checkpoint: check `git log` since session start BEFORE writing
   conductor files; stage explicit paths, never `git add -A`; reconcile the
   other session's pulse/relay edits, never clobber (2026-08-06).
