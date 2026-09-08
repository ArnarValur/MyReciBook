# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*
> **Updated:** 2026-09-08

## 📍 Now
- Phase: closed test, Play review PASSED. Play holds 0.20.0+42 (tag
  `the-first-0.20.0+42`); main is at 0.21.0+44 (debug install only).
- Closed "Alpha" (NO+SE) live; Arnar + Höddi opted in through the closed join
  link. 12-tester rule is NOT an mvp-build item; tester outreach avenues are
  a topic for the 2026-09-08 session (Arnar).
- Two apps on the phone: the Play build and "MyReciBook dev" (debug + profile
  builds carry package suffix .dev, own Firebase Android app in the dev
  project). Debugger → dev backend, which serves everything until launch;
  prod stays untouched until the paid release (prod.env + build-release.sh).
- Tags reworked to Direction A 2026-09-03, verified on the dev app: one grid
  + tag-tile strip, one editor sheet, import tags as suggestions, Settings →
  Tags deleted. Dark sheets + dialogs lifted to surfaceContainer (unverified).
- Drive on prod DONE (Android OAuth client on Play's app-signing SHA-1,
  consent screen in production). App Check registered on Play's app-signing
  SHA-256; the server does NOT require it yet.
- Offer = terms: 1,200 grant never refills, top-up 600 for $5; both proxies
  live on the no-refill ledger.
- PROD LIVE: myrecibook.com + www on Cloud Run; Firestore eur3; keys in Secret
  Manager; Firebase Production. Contact form posts to DEV on purpose.

## 🚀 Active tracks
- mvp-build — THE focus. Quota card BUILT (import sheet line, paywall
  counter, cap-reached screen, three honest 429 messages) — still awaiting
  Arnar's eyes on the dev app. Open: billing seam, listing + welcome
  screenshots, App Check enforcement on the server, CLI Play publishing.
- ouroboros — side experiment in the worktree, never blocks mvp-build. Slice
  one a–f built + tested on branch `ouroboros`.
- market — open: Q2 export recon (Arnar running), Q5 steal list, Q6 cadence.
  i18n PAUSED (Decision 2).

## ⚠️ Blockers
- None open.

## 📌 Parked
- tag reorder has no UI (tiles follow tags.json order) · "see all" for a long
  tag strip · i18n paused · nutrition dormant · borrowed listing photos ·
  is/sv stale money rows · stale test recipe_diary_chain ×1 (cookbook_view
  repaired, shell green 2026-09-08) · 34 deps outdated · serving labels
  ignore units toggle · pack math can't reach density table · audit
  H2/M1-M6/L1-L4 · Faroese delegate · Drive sign-in untested in the dev app ·
  handoff remainder · measure real usage.
