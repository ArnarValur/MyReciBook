# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*
> **Updated:** 2026-09-10

## 📍 Now
- Phase: closed test, Play review PASSED. 0.21.0+45 on the closed "alpha" track.
  Arnar's phone: Play build + dev build (.dev, profile, dev.env) beside it.
- PROD extraction fixed 2026-09-10: prod Cloud Run account had no Firestore
  role → every rescue 503 quota_unavailable; prod had never completed one.
  roles/datastore.user granted by Arnar; end-to-end 200 verified.
- Paste-a-link door BUILT on the + sheet ("Or fetch from the internet", clipboard
  pre-fill, ImportLink → shared-link review, spent grant → cap). Dev app, no stamp.
- People Inc. wall: allrecipes / simplyrecipes / seriouseats answer 402 to any
  non-browser fetch, Gemini url_context too. Only road: hidden WebView fetch
  after a refusal. NOT built. Backup-API talk = next session.
- Failed rescues reach Crashlytics as non-fatals (mode · status · reason · host,
  never URL); first event seen from Arnar's phone. Crashlytics readable from the
  terminal (Firebase MCP `firebase`, docs/gcp-project-facts.md). Drive redirect
  crash fixed (flutter_deeplinking_enabled=false; scrubber drops code/state/token).
- EMULATOR = second handset (pixel_7_api_35, ANDROID_SERIAL=emulator-5554;
  seed_emulator.py · shoot_emulator.sh · shots.mjs · render.mjs).
- PROD LIVE: myrecibook.com, Firestore eur3, Secret Manager, GA4 behind
  consent, Drive OAuth done, App Check registered not enforced. Contact form
  posts to DEV on purpose. Offer: 1,200 grant never refills, 600 for $5.

## 🚀 Active tracks
- mvp-build — THE focus. Open: listing + welcome slide shots (emulator),
  billing seam, App Check enforcement, link door + crash pipe verify → stamp,
  hidden-WebView fetch decision.
- market — open: Q2 export recon (Arnar), Q5 steal list, Q6 cadence.

## ⚠️ Blockers
- None open.

## 📌 Parked
- grocery list unpolished · ouroboros PARKED · consent note English-only · tag
  reorder no UI · i18n paused · nutrition dormant · borrowed listing photos ·
  is/sv stale money rows · stale test ×1 · 34 deps outdated · serving labels
  ignore units · pack math vs density · audit H2/M1-M6/L1-L4 · Faroese delegate
  · handoff remainder · measure real usage · empty-state "or paste a link" line.
