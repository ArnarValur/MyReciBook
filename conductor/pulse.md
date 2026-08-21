# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-22 — checkpoint

## 📍 Now
- Phase: build. 0.10.2+10 on main. Only main exists, local and remote.
- Extraction server is live: myrecibook-proxy, Cloud Run europe-west1.
  Verified end to end — real Gemini call, ledger persisted, rate limiter live.
- Both import doors verified on the phone through the live server 2026-08-22:
  screenshot rescue and URL share both fetch the recipe (Arnar).
- Gemini key in Secret Manager only; release build checked, no key inside. app/dev.env holds the server URL.
- Offer in code: two weeks free, then 1200 a year. Limits 10/min, 50/day per buyer, 2000/day overall.
- Crash reporting ships ON. Switch in Settings turns it off, recipe text is
  scrubbed, and "Send test report" behind the version footer proves the pipe.
- Build 9 on the phone and on the tester link (App Distribution), no testers
  added. Full suite 697 green.
- Play developer account live and verified. Nothing uploaded to Play yet.
- Docs: pre-launch-audit-2026-08-21 · runbook-dev-deploy · gcp-project-facts. gcloud: ~/google-cloud-sdk/bin, not on PATH.
- Starter foods values UNVERIFIED vs USDA — Arnar's run; patch starter_foods.dart.

## 🚀 Active tracks
- mvp-build — server done and deployed. Billing seam open, unstarted.
- diary — categories 1-4 in code. Open: device verify of 2-4, starter values.
- nutrition — open: grocery package-size math, label-photo fallback.

## ⚠️ Blockers
- Play grants production access only after 12 people have the app installed
  from Play's test track for 14 days straight. Nobody recruited. Not the same
  thing as the 14 free days a buyer gets.
- Privacy policy + Play data safety form: nothing written, blocks submission.
- App-proof check registered but not required, and the app sends no token from
  a sideloaded build — Play Integrity only attests installs from Play.

## 📌 Parked
- i18n until paid v1 · user feedback channel · category icons/colours · serving
  rescale · step ↔ ingredient chips · label-photo fallback · meal names UI ·
  copy-to-date UI · day nutrient table · row reorder · multi-barcode per image ·
  orphan image cleanup · accessibility pass · Dropbox production approval ·
  Play key backup · audit items H2 and M1-M6 and L1-L4.
