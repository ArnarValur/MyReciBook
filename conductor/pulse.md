# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-22 — checkpoint

## 📍 Now
- Phase: build. 0.11.0+10. Branch i18n holds the language work; main is at 0.10.2+10.
- Extraction server live: myrecibook-proxy, Cloud Run europe-west1. Verified end to end.
- Both import doors verified on a phone through the live server (Arnar).
- Gemini key in Secret Manager only; release build carries none. app/dev.env holds the server URL.
- Offer in code: two weeks free, then 1200 a year. Limits 10/min, 50/day per buyer, 2000/day overall.
- Crash reporting ships ON, switch in Settings, recipe text scrubbed, test-report door proves the pipe.
- Build 9 on the phone and on the tester link (App Distribution), no testers added.
- Play developer account live and verified. Nothing uploaded to Play yet.
- Docs: pre-launch-audit-2026-08-21 · runbook-dev-deploy · gcp-project-facts. gcloud: ~/google-cloud-sdk/bin, not on PATH.
- Starter foods values UNVERIFIED vs USDA — Arnar's run; patch starter_foods.dart.
- Serving labels ignore the units pill: convertUnits touches recipe lines only, so "1 cup" shows in metric. Noted in the nutrition plan.

## 🚀 Active tracks
- mvp-build — server done and deployed. Billing seam open, unstarted.
- diary — categories 1-4 in code. Open: device verify of 2-4, starter values.
- nutrition — open: grocery package-size math, label-photo fallback, serving-label conversion.
- i18n — foundation done on branch i18n, English + Íslenska offered, nine more parked at 31 strings. Open: the string sweep. Arnar takes one language at a time.

## ⚠️ Blockers
- Play grants production access only after 12 people have the app installed
  from Play's test track for 14 days straight. Arnar is recruiting Polish
  testers. Not the same thing as the 14 free days a buyer gets.
- Privacy policy + Play data safety form: nothing written, blocks submission.
- App-proof check registered but not required, and the app sends no token from
  a sideloaded build — Play Integrity only attests installs from Play.

## 📌 Parked
- user feedback channel (i18n needs it — a wrong string with nowhere to report
  it stays wrong) · category icons/colours · serving rescale · step ↔
  ingredient chips · label-photo fallback · meal names UI · copy-to-date UI ·
  day nutrient table · row reorder · multi-barcode per image · orphan image
  cleanup · accessibility pass · Dropbox production approval · Play key backup ·
  audit items H2 and M1-M6 and L1-L4.
