# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-22 — checkpoint

## 📍 Now
- Phase: build. 0.10.2+10 on main. Only main exists, local and remote.
- Extraction server is live: myrecibook-proxy, Cloud Run europe-west1.
  Verified end to end — real Gemini call, ledger persisted, rate limiter live.
- Both import doors verified on the phone through the live server 2026-08-22:
  screenshot rescue and URL share both fetch the recipe (Arnar).
- Gemini key is in Secret Manager only. Release build checked: no key inside.
  app/dev.env carries the server URL instead.
- Offer in code: two weeks free, then 1200 a year. Limits 10/min and 50/day per
  buyer, 2000/day overall.
- Crash reporting ships ON. Switch in Settings turns it off, recipe text is
  scrubbed, and "Send test report" behind the version footer proves the pipe.
- Build 9 on the phone and on the tester link (App Distribution), no testers
  added. Full suite 697 green.
- Audit: docs/pre-launch-audit-2026-08-21.md. Hand-work: runbook-dev-deploy.md.
  Identifiers: gcp-project-facts.md. gcloud: ~/google-cloud-sdk/bin, not on PATH.
- Starter foods VALUES UNVERIFIED vs USDA — Arnar owns that run; patch
  domain/starter_foods.dart only.

## 🚀 Active tracks
- mvp-build — server done and deployed. Billing seam open, unstarted.
- diary — categories 1-4 in code. Open: device verify of 2-4, starter values.
- nutrition — open: grocery package-size math, label-photo fallback.
- Play developer account live and verified. Closed test — 12 testers, 14
  unbroken days — is the only gate left before production access.

## ⚠️ Blockers
- Privacy policy + Play data safety form: nothing written, blocks submission.
- App-proof check registered but not required, and the app sends no token from
  a sideloaded build — Play Integrity only attests installs from Play.

## 📌 Parked
- i18n until paid v1 · user feedback channel · category icons/colours · serving
  rescale · step ↔ ingredient chips · label-photo fallback · meal names UI ·
  copy-to-date UI · day nutrient table · row reorder · multi-barcode per image ·
  orphan image cleanup · accessibility pass · Dropbox production approval ·
  Play key backup · audit items H2 and M1-M6 and L1-L4.
