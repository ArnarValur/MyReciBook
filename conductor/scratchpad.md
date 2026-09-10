# Scratchpad

Arnar's notes. Fresh page pulled 2026-09-01 (housekeeping session); old page in git history.

## Live
- Grocery list revamp — ask Arnar what he wants changed.
- Import from other apps — research done: docs/library-import-research.md (market track Q2).
- User feedback channel — Crashlytics covers the error half; feedback half still open.
- Tester recruitment / branching out to networks — parked by Arnar, he has ideas, ask him.

## 2026-08-22 — roundup links ("10 Easy One-Pot Pasta Recipes") — feasible, not ordered
- A listicle can import on the free path: harvest the ItemList's child links →
  each child page has full Recipe JSON-LD → existing BatchModel queue. Zero AI calls.
- New plumbing: BatchItem carries a URL, share-intent forks batch-vs-single.
- Plan at ~/.claude/plans/question-if-a-link-glowing-unicorn.md. Feasibility only — not approved.

## Pointers (decisions that used to live here)
- Cap + top-up (1200/yr · +1200 for $5 · rise-never-fall) — docs/ai-cap-mechanics.md, printed in terms.
- Weekend plan 2026-08-21 (stages 1–4) — all shipped; story in relay/pulse-archive.

## 2026-09-10 — the People Inc. wall, and intel on failed rescues (Arnar: note it)
- allrecipes.com, simplyrecipes.com, seriouseats.com (all People Inc.) answer
  HTTP 402 to every fetch that is not a real browser — Chrome user agent and
  browser headers do not pass, and Gemini's own url_context reader is blocked
  too (tested). bbcgoodfood.com and delish.com still answer 200. The app shows
  "The site wouldn't let us in"; the AI fallback never runs.
- Only workaround found: a hidden browser window in the app. Android's built-in
  WebView (Chrome engine, no new library) loads the link off screen, and on
  page-finished one line of script hands the page text to the existing
  LinkExtractor parser. Runs only after the plain fetch is refused (402/403).
  ~150 lines in the NetBridge + a small Dart fallback. Slower on those sites
  (full page with ads), and the wall may still raise a human check we cannot
  click. Not built; Arnar's call.
- Intel on failed rescues: Arnar wants to know which links fail and why. Hermes'
  read: the pipe already exists — CrashReporter → Crashlytics, behind the "Send
  crash reports" toggle, scrubbed. A failed link rescue as a non-fatal report
  (mode, HTTP status, site host — not the full URL) shows up grouped and counted
  in the Console, no new collection, no Firestore SDK in the app, no rules. A
  new Firestore collection buys the same facts for more moving parts. Dev-only
  fuller detail is possible behind a build flag. Not built; Arnar decides.
