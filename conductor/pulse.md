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
- ouroboros — opened 2026-09-01. D1–D3 Arnar's, D4–D7 leanings. PoC slice
  one in the worktree: 1a prompt + 1b parser committed, unwired; next 1b test → 1c.
- mvp-build — open: Play review outcome, S21 uninstall-dev → Play install →
  listing screenshots, App Check SHA, Drive OAuth consent on prod, billing
  seam, card on import sheet + paywall, welcome screenshots, CLI Play publishing.
- market — open: Q2 export recon (Arnar running), Q5 steal list (rides
  ouroboros), Q6 cadence. i18n PAUSED (Decision 2).

## ⚠️ Blockers
- Drive OAuth consent screen on prod NOT started — verification takes WEEKS.
- Listing screenshots need a release install (debug banner on dev build).

## 📌 Parked
- i18n paused · nutrition dormant · 429 means three things, app says one ·
  borrowed listing photos (takedown clause) · is/sv stale money rows · stale
  tests cookbook_view ×2 + recipe_diary_chain ×1 + shell ×2 · 34 deps outdated
  · serving labels ignore units toggle · pack math can't reach density table ·
  audit H2/M1-M6/L1-L4 · app-side Faroese needs a custom delegate (da falls).
