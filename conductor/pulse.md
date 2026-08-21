# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-20 — checkpoint

## 📍 Now
- Phase: build. 0.10.0+8 on the S21.
- Export live: one share button, PDF always, Google Docs when Drive is
  connected. Detail in tracks/export/plan.md.
- Export track done: both doors verified on the S21. Collection/meal-plan
  export stays unasked — do not build it blind.
- Nutrition wording lives once (domain/nutrient_display.dart nutritionWords):
  badge, PDF and Doc print identical lines, coverage note included.
- pdf 3.13.0 + printing 5.15.0 build clean under AGP 9.0.1 / Gradle 9.1.0.
- Starter foods VALUES UNVERIFIED vs USDA — Arnar owns that run; patch
  domain/starter_foods.dart only.
- workflow.md rules rewritten: version by what changed (+build only when an
  APK ships); tests get proposed, Arnar decides; one yes covers the whole
  request — never re-ask per step.

## 🚀 Active tracks
- diary — categories 1-4 in code. Open: S21 verify of 2-4, starter values,
  three link-picker test files pinned to the deleted drawer.
- nutrition — open: grocery package-size math, label-photo fallback.
- mvp-build — billing seam open, unstarted. Dev GCP project
  MyReciBook-Dev (gen-lang-client-0166122901).
- Play developer account live and verified (Merkurial-Studio, personal, Norway).
  Closed test — 12 testers, 14 unbroken days — is now the only gate left before
  production access, and it needs an installable alpha on the closed track.

## ⚠️ Blockers
- None.

## 📌 Parked
- i18n, parked until paid v1 (docs/i18n-report.md; only the stored-key /
  display-label split gets dearer with time) · Crashlytics · user feedback
  channel · category icons/colours · proxy deploy · durable cap store ·
  serving rescale · step ↔ ingredient chips · label-photo fallback · meal
  names UI · copy-to-date UI · day nutrient table · row reorder ·
  multi-barcode per image · orphan image cleanup · accessibility pass ·
  Dropbox production approval · Play key backup.
