# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-21 — checkpoint

## 📍 Now
- Phase: build. 0.10.1+8. Branch `harden/pre-launch-bake`, not folded to main.
- Pre-launch audit written: docs/pre-launch-audit-2026-08-21.md. Three blockers
  named; two are now code-complete, the third (privacy policy + Data Safety)
  is untouched and blocks Play submission.
- Crash reporting: nothing swallowed any more. Local ring buffer always,
  Crashlytics only on consent, recipe text scrubbed before upload.
- Proxy rebuilt: Firestore ledger, App Check verification, per-bucket rate
  limit, global daily breaker, refund on failure. 25 tests green.
- Proxy has NEVER been deployed — gcloud is not installed on PlutoII.
  Everything Arnar must do by hand: docs/runbook-dev-deploy.md.
- GCP identifiers now live in a file, not in chat: docs/gcp-project-facts.md.
- Starter foods VALUES UNVERIFIED vs USDA — Arnar owns that run; patch
  domain/starter_foods.dart only.

## 🚀 Active tracks
- diary — categories 1-4 in code. Open: device verify of 2-4, starter values.
- nutrition — open: grocery package-size math, label-photo fallback.
- mvp-build — billing seam open, unstarted. Dev GCP project MyReciBook-Dev
  (gen-lang-client-0166122901, project number 213431165631).
- Play developer account live and verified. Closed test — 12 testers, 14
  unbroken days — is the only gate left before production access, and it needs
  an installable alpha on the closed track.

## ⚠️ Blockers
- Privacy policy + Play Data Safety form: nothing written, blocks submission.
- App Check enforcement cannot be flipped until a build carrying
  google-services.json reaches the internal track.

## 📌 Parked
- i18n, parked until paid v1 (docs/i18n-report.md; only the stored-key /
  display-label split gets dearer with time) · user feedback channel ·
  category icons/colours · serving rescale · step ↔ ingredient chips ·
  label-photo fallback · meal names UI · copy-to-date UI · day nutrient
  table · row reorder · multi-barcode per image · orphan image cleanup ·
  accessibility pass · Dropbox production approval · Play key backup ·
  audit M1-M6 hardening (SSRF allowlist, cache pruning, ANR/isolates,
  pinned targetSdk, R8) · audit L1-L4.
