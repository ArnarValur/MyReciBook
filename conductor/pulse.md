# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-09-01 (night)

## 📍 Now
- Phase: first testers + Play review. "The First" 0.20.0+42 on internal —
  2 official testers, Arnar + Höddi both installed via Play. Closed "Alpha"
  (NO+SE) + en-GB listing submitted, in Play review.
- Internal-track testers do NOT count toward the 12×14d closed gate.
- Git: tag `the-first-0.20.0+42` = what Play holds; main moves freely, no
  develop branch, hotfix branches from the tag.
- Offer engine matches the terms: the 1,200 grant NEVER refills (Decision 1),
  `resets_at` gone from wire + app; top-up = 600 for $5 on the unlock card
  and in en/nb/da/fi/fo terms. Dev proxy redeployed 2026-09-01, no-refill
  live for testers. Prod proxy idle (nothing calls it) and still on OLD
  refill code — MUST redeploy before the first paying user.
- Market Decisions 2+3: i18n PAUSED (English copy still moving); listing
  short description = "…Pay once, no subscription." — words, never a number.
- Website: non-English pages carry the translation sticker (English governs);
  missing keys fall back to en (i18n.config.ts). Picker still hidden.
- PROD LIVE: myrecibook.com + www on Cloud Run; prod proxy smoke-tested;
  Firestore eur3; gemini+brevo keys in Secret Manager; Firebase Production.
  Contact form still posts to the DEV proxy on purpose.
- Prod key on prepaid Gemini credits (tier 3, Arnar manages balance).
- Release path ready, NOT for testers: app/prod.env (Drive client still
  DEV) + app/build-release.sh. Tester builds stay on dev.env + dev Firebase.
- Marco Pierre White easter eggs in site copy are deliberate — never "fix".
- .aab: `cd app && flutter build appbundle --release
  --dart-define-from-file=dev.env`. Debug: `adb install -r` + dev.env.

## 🚀 Active tracks
- mvp-build — open: proxy redeploy (dev+prod, ships no-refill ledger), Play
  review outcome, S21 uninstall-dev → Play install → listing screenshots,
  App Check SHA, Drive OAuth consent on prod, billing seam, card on import
  sheet + paywall, welcome screenshots.
- market — open: Q2 export recon (Arnar running), Q5 steal list, Q6 cadence.

## ⚠️ Blockers
- Drive OAuth consent screen on prod NOT started — verification takes WEEKS.
- Listing screenshots need a release install (debug banner on dev build).

## 📌 Parked
- i18n track paused (Decision 2; unfreeze order in market plan) · nutrition
  dormant · 429 means three things, app says one · borrowed listing photos
  (takedown clause) · is/sv stale "per år/á ári" rows await human pass ·
  stale tests cookbook_view ×2 + recipe_diary_chain ×1 + shell ×2 · 34 deps
  outdated · serving labels ignore units toggle · pack math can't reach
  density table · audit H2/M1-M6/L1-L4 · app-side Faroese needs a custom
  Flutter delegate (fallback da).
