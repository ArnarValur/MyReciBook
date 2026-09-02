# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-09-01 (late)

## 📍 Now
- Phase: first testers + Play review. 0.20.0+42 on internal, both testers
  proved rescue + URL import. Closed "Alpha" (NO+SE) + en-GB listing in review.
- Git: tag `the-first-0.20.0+42` = what Play holds; main moves freely, hotfix
  branches from the tag. Worktree ../MyReciBook-ouroboros = branch `ouroboros`
  (PoC; conductor files edited on main only).
- Offer = terms: 1,200 grant never refills, top-up 600 for $5 (card + en/nb/
  da/fi/fo terms). Dev + prod proxies live on the no-refill ledger.
- PROD LIVE: myrecibook.com + www on Cloud Run; Firestore eur3; keys in Secret
  Manager; Firebase Production; prod key on prepaid Gemini credits. Contact
  form posts to DEV on purpose. Website picker hidden, non-en pages stickered.
- Release path ready, NOT for testers: app/prod.env (Drive client still DEV)
  + app/build-release.sh. Tester builds stay on dev.env + dev Firebase.
- .aab: `cd app && flutter build appbundle --release
  --dart-define-from-file=dev.env`. Debug: `adb install -r` + dev.env.

## 🚀 Active tracks
- ouroboros — side experiment in the worktree, NOT on the 1.0 path and never
  blocks it (Arnar 2026-09-02). Slice one a–f built + tested on branch
  `ouroboros`; if it proves itself we look at folding it in, not before.
- mvp-build — THE focus (Arnar 2026-09-02). Play build installed on the
  handset, dev build gone. Open: Play review outcome, listing screenshots,
  App Check SHA, billing seam, card on import sheet + paywall, welcome
  screenshots, CLI Play publishing. Drive OAuth on prod: Arnar started it.
- market — open: Q2 export recon (Arnar running), Q5 steal list (rides
  ouroboros), Q6 cadence. i18n PAUSED (Decision 2).

## ⚠️ Blockers
- Drive OAuth consent screen on prod — Arnar started 2026-09-02; verification
  takes WEEKS, so it stays named until Google answers.

## 📌 Parked
- i18n paused · nutrition dormant · 429 means three things, app says one ·
  borrowed listing photos (takedown clause) · is/sv stale money rows · stale
  tests cookbook_view ×2 + recipe_diary_chain ×1 + shell ×2 · 34 deps outdated
  · serving labels ignore units toggle · pack math can't reach density table ·
  audit H2/M1-M6/L1-L4 · app-side Faroese needs a custom delegate (da falls).
