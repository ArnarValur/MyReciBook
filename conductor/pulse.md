# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-09-01 (night)

## 📍 Now
- Phase: first testers + Play review. "The First" 0.20.0+42 on internal —
  2 official testers, Arnar + Höddi both installed via Play and proved
  rescue + URL import live. Closed "Alpha" (NO+SE) + en-GB listing in
  Play review. Internal testers do NOT count toward the 12×14d gate.
- Git: tag `the-first-0.20.0+42` = what Play holds; main moves freely, no
  develop branch, hotfix branches from the tag.
- Offer engine matches the terms: the 1,200 grant NEVER refills (Decision 1),
  `resets_at` gone from wire + app; top-up = 600 for $5 on the unlock card
  and in en/nb/da/fi/fo terms. BOTH proxies redeployed 2026-09-01 —
  dev + prod live on the no-refill ledger, health + model guard green.
- Market Decisions 2+3: i18n PAUSED (English copy still moving); listing
  short description = "…Pay once, no subscription." — words, never a number.
- Website: non-English pages carry the translation sticker (English governs);
  missing keys fall back to en (i18n.config.ts). Picker still hidden.
- PROD LIVE: myrecibook.com + www on Cloud Run; Firestore eur3; keys in
  Secret Manager; Firebase Production. Contact form posts to DEV on purpose.
- Prod key on prepaid Gemini credits (tier 3, Arnar manages balance).
- Release path ready, NOT for testers: app/prod.env (Drive client still
  DEV) + app/build-release.sh. Tester builds stay on dev.env + dev Firebase.
- Marco Pierre White easter eggs in site copy are deliberate — never "fix".
- .aab: `cd app && flutter build appbundle --release
  --dart-define-from-file=dev.env`. Debug: `adb install -r` + dev.env.

## 🚀 Active tracks
- ouroboros — opened 2026-09-01. PoC slice one in worktree
  ../MyReciBook-ouroboros (branch `ouroboros`); merges only after device verify.
- mvp-build — open: Play review outcome, S21 uninstall-dev → Play install →
  listing screenshots, App Check SHA, Drive OAuth consent on prod, billing
  seam, card on import sheet + paywall, welcome screenshots, CLI Play
  publishing at next ship.
- market — open: Q2 export recon (Arnar running), Q5 steal list, Q6 cadence.

## ⚠️ Blockers
- Drive OAuth consent screen on prod NOT started — verification takes WEEKS.
- Listing screenshots need a release install (debug banner on dev build).

## 📌 Parked
- i18n paused (Decision 2; unfreeze order in market plan) · nutrition dormant ·
  429 means three things, app says one · borrowed listing photos (takedown
  clause) · is/sv stale "per år/á ári" rows await human pass · stale tests
  cookbook_view ×2 + recipe_diary_chain ×1 + shell ×2 · 34 deps outdated ·
  serving labels ignore units toggle · pack math can't reach density table ·
  audit H2/M1-M6/L1-L4 · app-side Faroese needs a custom delegate (da falls).
