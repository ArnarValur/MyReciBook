# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*
*Live state and open questions ONLY. A shipped feature belongs in its track plan.*

> **Updated:** 2026-08-30

## 📍 Now
- Phase: build. 0.19.0+37 on main and on the phone. Branch i18n sits at 0.11.0+10.
- APKs ONLY via app/deploy-s21.sh — a plain `flutter build apk` ships no proxy
  URL and placeholder connector keys. docs/runbook-dev-deploy.md §5.
- Extraction server live: myrecibook-proxy, Cloud Run europe-west1. Gemini key in
  Secret Manager only; app/dev.env holds server URL + Drive/Dropbox keys.
- gcloud lives in ~/google-cloud-sdk/bin, not on PATH.
- Offer in code: pay once; AI grace two weeks free, then 1200 rescues/year.
  Limits 10/min, 50/day per buyer, 2000/day overall. Price tag NOT decided
  ($25 on the site is placeholder). Crash reporting ON, recipe text scrubbed.
- Tester link still on build 9. Play account live, nothing uploaded. Play app
  entry not created — create as FREE + one-time IAP (trial needs free install).
- Test comb of all 72 files: docs/test-comb-2026-08-29.md — repairs proposed
  (icon-binding hole, arb tautology, 5 coverage holes), Arnar undecided.
  cookbook_view ×2 still red — stale "no covers in list view" asserts, lib right.
- starter_foods green ≠ USDA verification — it pins the unverified transcription.
- Cadence: analyze between changes → touched files warm → full suite at bedtime.
- website/ — card-box landing COMPLETE + polished in Nuxt 4: index +
  privacy/terms/contact (drafts, stamped) + 404, SEO formal, dark mode.
  410px mobile pass done (website/polish-list.md, all ☑). Rescue strip is
  theme-matched: tiramisu light set / beef-broccoli dark set. Price shown $25
  (still placeholder, swept repo-wide incl. kUnlockPrice). Remaining copy
  flags: website/copy-notes.md. Staging on MyReciBook-Dev:
  https://myrecibook-website-staging-213431165631.europe-west1.run.app
  (noindex-guarded; real domain unmapped on purpose). No track yet.

## 🚀 Active tracks
- mvp-build — server deployed, onboarding shipped, rescue flow polished 0.19.0.
  Open: privacy policy (website draft doubles as source), Play data safety
  form, welcome slide screenshots, billing seam (unstarted).
- diary — meal hours, cold start, photo cards shipped. Open: device verify ·
  oats label re-read · starter_foods.dart UNVERIFIED vs USDA, his run.
- tags — shelf + editor shipped. Open: strings are English literals.
- nutrition — open: grocery package-size math, serving-label conversion.
- i18n — foundation on branch i18n; control HIDDEN until one language done.

## ⚠️ Blockers
- Play: 12 testers × 14 days before production. Arnar recruiting; app entry +
  merchant profile not yet created in Play Console.
- Privacy policy + data safety form: website draft awaits Arnar's approval.

## 📌 Parked
- share-a-copy invite text + PDF footer breadcrumb (Arnar's new session) · quick add · typed custom emoji · net-weight landing · skipped-files list · day-rollover hour · index-file pantry cache.
- feedback channel · serving rescale · step ↔ ingredient chips · label-photo fallback · copy-to-date UI · row reorder · multi-barcode · orphan image cleanup · listicle import · accessibility pass · Dropbox approval · Play key backup · audit H2, M1-M6, L1-L4 · website OG per-page images.
