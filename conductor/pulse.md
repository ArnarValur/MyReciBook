# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*
> **Updated:** 2026-09-09

## 📍 Now
- Phase: closed test, Play review PASSED. Play holds 0.20.0+42 (tag
  `the-first-0.20.0+42`); main is at 0.21.0+44 (debug install only).
- Closed "Alpha" (NO+SE) live; Arnar + Höddi opted in. Outreach sequence in
  docs/tester-outreach-gameplan.md, nothing acted on.
- Website tester marketing REMOVED 2026-09-09 (Arnar): no seat counter he must
  hand-edit. Contact form's tester tick + proxy handling kept whole. On branch
  `tester-outreach`, NOT merged — the fold to main is Arnar's call.
- Contact + terms pages said myrecibook@google.com (impossible domain); now
  myrecibook@gmail.com, where CONTACT_TO_EMAIL always delivered.
- Two apps on the phone: the Play build and "MyReciBook dev" (.dev suffix, own
  Firebase app). Dev backend serves all until launch.
- Website analytics LIVE, verified in GA4 Realtime; consent note gates the tag.
- Tags on Direction A, verified. Dark sheets lifted (unverified). Drive on prod
  DONE. App Check registered on Play's SHA-256, server does NOT require it.
- Offer = terms: 1,200 grant never refills, top-up 600 for $5; both proxies live
  on the no-refill ledger.
- PROD LIVE: myrecibook.com + www on Cloud Run; Firestore eur3; keys in Secret
  Manager; Firebase Production. Contact form posts to DEV on purpose.

## 🚀 Active tracks
- mvp-build — THE focus. Quota card BUILT, still awaiting Arnar's eyes on the
  dev app. Open: billing seam, listing + welcome screenshots, App Check
  enforcement on the server, CLI Play publishing.
- market — open: Q2 export recon (Arnar running), Q5 steal list, Q6 cadence.

## ⚠️ Blockers
- None open.

## 📌 Parked
- website "pocket" section promises barcode, trends and dark mode over a plain
  cookbook screenshot. Arnar is gathering pantry + barcode screenshots; the
  section gets rebuilt around them.
- ouroboros PARKED 2026-09-09 (Arnar) — branch + worktree kept as they stand.
- branch `agents/app-overview-and-features` is empty, safe to delete (blocked).
- consent note English-only · tag reorder has no UI · "see all" for a long tag
  strip · i18n paused · nutrition dormant · borrowed listing photos · is/sv stale
  money rows · stale test recipe_diary_chain ×1 · 34 deps outdated · serving
  labels ignore units · pack math can't reach density table · audit H2/M1-M6/
  L1-L4 · Faroese delegate · Drive sign-in untested in dev app · handoff
  remainder · measure real usage.
