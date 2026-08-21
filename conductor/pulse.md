# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-21 — checkpoint

## 📍 Now
- Phase: build. 0.10.1+8. Branch `harden/pre-launch-bake`, NOT folded to main.
- Pre-launch audit: docs/pre-launch-audit-2026-08-21.md. Of three blockers, two
  are fixed; privacy policy + Data Safety is untouched and blocks submission.
- Proxy is LIVE: myrecibook-proxy, Cloud Run europe-west1 (Firestore is eur3).
  Verified end to end — real Gemini call, ledger persisted, rate limiter live.
- Gemini key is in Secret Manager ONLY. Release APK built and checked: no key
  in the binary. dev.env carries EXTRACTION_PROXY_URL instead.
- Crash reporting: nothing swallowed. Ring buffer always, Crashlytics on
  consent, recipe text scrubbed. Ships OFF — the default is Arnar's call.
- gcloud is at ~/google-cloud-sdk/bin, NOT on PATH.
- GCP identifiers: docs/gcp-project-facts.md. Hand-work: runbook-dev-deploy.md.
- Starter foods VALUES UNVERIFIED vs USDA — Arnar owns that run; patch
  domain/starter_foods.dart only.

## 🚀 Active tracks
- diary — categories 1-4 in code. Open: device verify of 2-4, starter values.
- nutrition — open: grocery package-size math, label-photo fallback.
- mvp-build — billing seam open, unstarted. MyReciBook-Dev
  (gen-lang-client-0166122901, number 213431165631).
- Play developer account live and verified. Closed test — 12 testers, 14
  unbroken days — is the only gate left before production access, and it needs
  an installable alpha on the closed track.

## ⚠️ Blockers
- Privacy policy + Play Data Safety form: nothing written, blocks submission.
- App Check registered but NOT enforced and the app sends no token —
  google-services.json is missing, so the proxy still trusts a header the
  client invents. Last open half of audit B1.
- Budgets and prepay credits not set. Arnar's, and the only real spend ceiling.

## 📌 Parked
- i18n until paid v1 (docs/i18n-report.md) · user feedback channel · category
  icons/colours · serving rescale · step ↔ ingredient chips · label-photo
  fallback · meal names UI · copy-to-date UI · day nutrient table · row
  reorder · multi-barcode per image · orphan image cleanup · accessibility
  pass · Dropbox production approval · Play key backup · audit H2 (plaintext
  tokens) and M1-M6 · audit L1-L4.
