# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*
> **Updated:** 2026-09-08

## 📍 Now
- Phase: closed test, Play review PASSED. Play holds 0.20.0+42 (tag
  `the-first-0.20.0+42`); main is at 0.21.0+44 (debug install only).
- Closed "Alpha" (NO+SE) live; Arnar + Höddi opted in. Tester + outreach
  research landed as docs/tester-outreach-gameplan.md (Cowork, 2026-09-08) —
  sequence only, nothing scheduled, nothing acted on.
- Two apps on the phone: the Play build and "MyReciBook dev" (suffix .dev, own
  Firebase app in the dev project). Dev backend serves everything until launch;
  prod waits for the paid release (prod.env + build-release.sh).
- Website analytics LIVE 2026-09-08, verified in GA4 Realtime. Consent note
  blocks the tag until the visitor accepts; ids in docs/gcp-project-facts.md.
  Google's "Test installation" scan can never pass — its robot never accepts.
- Tags on Direction A, verified. Dark sheets lifted (unverified). Drive on
  prod DONE. App Check registered on Play's SHA-256, server does NOT require it.
- Offer = terms: 1,200 grant never refills, top-up 600 for $5; both proxies
  live on the no-refill ledger.
- PROD LIVE: myrecibook.com + www on Cloud Run; Firestore eur3; keys in Secret
  Manager; Firebase Production. Contact form posts to DEV on purpose.

## 🚀 Active tracks
- mvp-build — THE focus. Quota card BUILT, still awaiting Arnar's eyes on the
  dev app. Open: billing seam, listing + welcome screenshots, App Check
  enforcement on the server, CLI Play publishing.
- ouroboros — side experiment in the worktree, never blocks mvp-build. Slice
  one a–f built + tested on branch `ouroboros`.
- market — open: Q2 export recon (Arnar running), Q5 steal list, Q6 cadence.
  i18n PAUSED (Decision 2).

## ⚠️ Blockers
- None open.

## 📌 Parked
- consent note is English-only (others fall back, picker hidden) · tag reorder
  has no UI · "see all" for a long tag strip · i18n paused · nutrition dormant
  · borrowed listing photos · is/sv stale money rows · stale test
  recipe_diary_chain ×1 · 34 deps outdated · serving labels ignore units
  toggle · pack math can't reach density table · audit H2/M1-M6/L1-L4 ·
  Faroese delegate · Drive sign-in untested in the dev app · handoff
  remainder · measure real usage.
