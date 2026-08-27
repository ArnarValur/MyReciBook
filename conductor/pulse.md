# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-27

## 📍 Now
- Phase: build. 0.16.0+21 on main and on the phone. Branch i18n is level with 0.11.0+10 and is where language work continues.
- Build APKs ONLY via app/deploy-s21.sh — plain `flutter build apk` ships no proxy URL and placeholder connector keys.
- Food surfaces redrawn to the diary/pantry mockups: pantry shelf, unified product page, tabbed add sheet, Trends. Arnar sees rough corners, unlisted.
- Trends reaches a year as 1 directory listing + one read per logged day, cached for the session only.
- Pantry fold state persists in settings.json; the SAF folder pointer and onboarding marker sit in device.json, excluded from Android backup.
- Extraction server live: myrecibook-proxy, Cloud Run europe-west1. Verified end to end.
- Gemini key in Secret Manager only; release build carries none. app/dev.env holds the server URL and the Drive/Dropbox keys.
- Label reading costs one AI call on the same fair-use budget as a recipe import; barcode lookups are free.
- Offer in code: two weeks free, then 1200 a year. Limits 10/min, 50/day per buyer, 2000/day overall.
- Crash reporting ships ON, switch in Settings, recipe text scrubbed, test-report door proves the pipe.
- Build 21 on the phone. Tester link still on 9. Play account live, nothing uploaded.
- Docs: pre-launch-audit-2026-08-21 · runbook-dev-deploy · gcp-project-facts. gcloud: ~/google-cloud-sdk/bin, not on PATH.
- Starter foods values UNVERIFIED vs USDA — Arnar's run; patch starter_foods.dart.
- Serving labels ignore the units pill: convertUnits touches recipe lines only, so "1 cup" shows in metric.
- Link import writes tags from the site's recipeCategory/recipeCuisine/keywords, up to 8. Review screen shows them before save.
- Full suite has not run since 2026-08-21. Everything since is per-file green only.

## 🚀 Active tracks
- mvp-build — server deployed, onboarding shipped. Billing seam open, unstarted.
- diary — Food redrawn to design, Trends built. Open: product photos on diary and add-sheet cards, device verify.
- tags — shipped end to end. Open: strings are English literals, not gen_l10n keys.
- nutrition — open: grocery package-size math, serving-label conversion.
- i18n — foundation on main, language control HIDDEN until a language is finished.
  Open: the string sweep, one language at a time.

## ⚠️ Blockers
- Play grants production access only after 12 people have the app installed
  from Play's test track for 14 days straight. Arnar is recruiting Polish
  testers. Not the same thing as the 14 free days a buyer gets.
- Privacy policy + Play data safety form: nothing written, blocks submission.
- App-proof check registered but not required, and the app sends no token from
  a sideloaded build — Play Integrity only attests installs from Play.

## 📌 Parked
- Quick add — engine real and tested, door hidden behind kQuickAddEnabled.
- Welcome slide screenshots — Arnar's crops; drop into kSlides in slides_screen.
- Net weight off a label has nowhere to land — Product has no pack-size field
  beyond quantity; feeds the grocery package-size work.
- user feedback channel · serving rescale · step ↔ ingredient chips ·
  label-photo fallback in recipes · meal names UI · copy-to-date UI ·
  row reorder · multi-barcode per image · orphan image cleanup ·
  roundup/listicle link import · accessibility pass · Dropbox production
  approval · Play key backup · audit items H2 and M1-M6 and L1-L4.
