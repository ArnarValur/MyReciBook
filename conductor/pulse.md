# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-09-01 (night)

## 📍 Now
- Phase: first testers + Play review. "The First" 0.20.0+42 live on internal.
  Submitted 2026-09-01 and now in Play review: closed testing "Alpha"
  (Norway+Sweden, email-list testers), en-GB store listing, and ALL app
  content forms (privacy URL, sign-in, ads, content rating — Brazil 14+,
  target 18+, data safety collected-only, financial none, health nutrition).
- PROD IS LIVE 2026-09-01: myrecibook.com + www on Cloud Run
  (myrecibook-website, cert issued, Namecheap DNS set). Prod proxy
  https://myrecibook-proxy-pp5bdjjhoq-ew.a.run.app smoke-tested; Firestore
  (default) eur3; gemini-api-key + brevo-api-key in prod Secret Manager;
  Firebase linked, env Production. Contact form still posts to the DEV
  proxy on purpose (plan step 6 decision).
- Prod key is on prepaid Gemini credits (tier 3, Arnar manages balance).
- Release path ready, NOT for testers: app/prod.env (Drive client still
  DEV — swap after consent verification) + app/build-release.sh (swaps
  google-services-prod.json in, builds .aab off prod.env, restores dev).
  Tester builds stay on dev.env + dev Firebase.
- Play listing drafts: docs/play-store-listing.md (texts, from website copy)
  + docs/MyReciBook-logo/assets/play/feature-graphic-1024x500.png.
- Marco Pierre White easter eggs in site copy are deliberate — never "fix".
- .aab: `cd app && flutter build appbundle --release
  --dart-define-from-file=dev.env`. Debug: `adb install -r` + dev.env.

## 🚀 Active tracks
- mvp-build — open: Play review outcome, S21 uninstall-dev → Play install →
  listing screenshots, App Check (Play signing SHA-256), Drive OAuth consent
  on prod, billing seam, card on import sheet + paywall, welcome screenshots.
- i18n — app foundation on branch, untouched; website picker hidden.

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
  density table · audit H2/M1-M6/L1-L4 · is/sv translations await the two.
