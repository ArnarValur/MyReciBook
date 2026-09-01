# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-09-01 (late)

## 📍 Now
- Phase: first testers + Play review. "The First" 0.20.0+42 on internal —
  2 official testers, Arnar + Höddi both installed via Play. Closed "Alpha"
  (NO+SE) + en-GB listing submitted, in Play review.
- Internal-track testers do NOT count toward the 12×14d closed gate.
- Git: tag `the-first-0.20.0+42` = what Play holds; main moves freely, no
  develop branch, hotfix branches from the tag. Old i18n branch deleted.
- Website i18n: nb translated (Gemini) + merged to main; da/fi/fo still
  skeletons awaiting their Gemini pass. Picker still hidden. Brief in
  website/i18n/TRANSLATE.md, parity check scripts/check-locales.mjs.
  en/is/sv human-owned — the agent keeps off them.
- PROD LIVE: myrecibook.com + www on Cloud Run; prod proxy smoke-tested;
  Firestore eur3; gemini+brevo keys in Secret Manager; Firebase Production.
  Contact form still posts to the DEV proxy on purpose.
- Prod key on prepaid Gemini credits (tier 3, Arnar manages balance).
- Release path ready, NOT for testers: app/prod.env (Drive client still
  DEV) + app/build-release.sh. Tester builds stay on dev.env + dev Firebase.
- Play listing drafts: docs/play-store-listing.md + feature graphic.
- Marco Pierre White easter eggs in site copy are deliberate — never "fix".
- .aab: `cd app && flutter build appbundle --release
  --dart-define-from-file=dev.env`. Debug: `adb install -r` + dev.env.

## 🚀 Active tracks
- mvp-build — open: Play review outcome, S21 uninstall-dev → Play install →
  listing screenshots, App Check SHA, Drive OAuth consent on prod, billing
  seam, card on import sheet + paywall, welcome screenshots.
- i18n — website leg on branch website-i18n (Gemini translates nb/da/fi/fo);
  app string sweep still open.
- market — Q1 bounded recurring cost is live, touches the offer/engine blocker.

## ⚠️ Blockers
- Drive OAuth consent screen on prod NOT started — verification takes WEEKS.
- Listing screenshots need a release install (debug banner on dev build).
- OFFER CONTRADICTS ENGINE: terms say nothing resets,
  firestore_ledger.dart:206 refills yearly; 429 triple-meaning bug rides.

## 📌 Parked
- nutrition dormant · borrowed listing photos (takedown clause) · crash
  scrubber strips keys/paths not prose · postalpha 4d preview stale (600) ·
  stale tests cookbook_view ×2 + recipe_diary_chain ×1 + shell ×2 · 34 deps
  outdated · serving labels ignore units toggle · pack math can't reach
  density table · audit H2/M1-M6/L1-L4 · is/sv translations await the two ·
  app-side Faroese needs a custom Flutter delegate (fallback da).
