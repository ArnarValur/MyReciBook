# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*
*Live state and open questions ONLY. A shipped feature belongs in its track plan.*

> **Updated:** 2026-08-28

## 📍 Now
- Phase: build. 0.18.3+34 on main and on the phone. Branch i18n sits at 0.11.0+10.
- APKs ONLY via app/deploy-s21.sh — a plain `flutter build apk` ships no proxy
  URL and placeholder connector keys. docs/runbook-dev-deploy.md §5.
- Extraction server live: myrecibook-proxy, Cloud Run europe-west1. Gemini key in
  Secret Manager only; app/dev.env holds server URL + Drive/Dropbox keys.
- gcloud lives in ~/google-cloud-sdk/bin, not on PATH.
- Offer in code: two weeks free, then 1200 a year. Limits 10/min, 50/day per
  buyer, 2000/day overall. Crash reporting ships ON, recipe text scrubbed.
- Tester link still on build 9. Play account live, nothing uploaded.
- Full suite has not run since 2026-08-21. Everything since is per-file green only.
- Agreed 2026-08-28: the full pass runs at bedtime, not mid-session. Arnar says
  "going to sleep" → comb the test files first (analysis + review), THEN run the
  whole suite detached to a log. Neither half happens without the other.
- website/ — Nuxt 4 + @nuxt/ui, no track yet. Card-box landing ported from the
  design canvas ("Website Card Box", docs/…website-2-mockups.zip): full page,
  local Material Symbols, responsive folds. Copy is canvas placeholder, NOT
  synced with decisions. Arnar is poking around, notes for a joint overview.

## 🚀 Active tracks
- mvp-build — server deployed, onboarding shipped. Open: privacy policy, Play
  data safety form, welcome slide screenshots, billing seam (unstarted).
- diary — meal hours, pantry cold start, photos on diary cards shipped. Open:
  device verify · Arnar re-reads the oats label (30.4 g folate predates the fix)
  · starter_foods.dart values still UNVERIFIED vs USDA, his run.
- tags — cookbook shelf + full-page editor shipped. Open: strings are English
  literals, not gen_l10n keys.
- nutrition — open: grocery package-size math, serving-label conversion.
- i18n — foundation on branch i18n; the language control stays HIDDEN until one
  language is finished. Open: the string sweep, inventory in coverage.md.

## ⚠️ Blockers
- Play grants production access only after 12 people have the app installed from
  Play's test track for 14 days straight. Arnar is recruiting testers.
- Privacy policy + Play data safety form: nothing written, blocks submission.

## 📌 Parked
- Quick add (kQuickAddEnabled) · typed custom emoji · net-weight landing · skipped-files tappable list · diary day-rollover hour · index-file pantry cache (the 1000+ door).
- user feedback channel · serving rescale · step ↔ ingredient chips · label-photo fallback in recipes · copy-to-date UI · row reorder · multi-barcode per image · orphan image cleanup · roundup/listicle link import · accessibility pass · Dropbox production approval · Play key backup · audit H2, M1-M6, L1-L4.
