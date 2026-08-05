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
