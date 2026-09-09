# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*
> **Updated:** 2026-09-09

## 📍 Now
- Phase: closed test, Play review PASSED. Play holds 0.20.0+42 (tag
  `the-first-0.20.0+42`); main is at 0.21.0+44 (debug install only).
- EMULATOR WORKS 2026-09-09. AVD pixel_7_api_35, Android 35 Play image, KVM on,
  hw.keyboard now yes. Proven: build, install, launch, screencap, screenrecord
  (3 min cap, no audio), uiautomator dump, input tap. The emulator binary is NOT
  on PATH; it lives at ~/Android/Sdk/emulator.
- Debug builds wear a DEBUG ribbon; profile builds do not. Profile APK with
  dev.env is built, ready to install for clean shots.
- Screenshot blocker: a fresh emulator is EMPTY. Recipes are plain JSON in the
  picked folder with images/ beside, so seeding is an adb push. Photos are the
  missing input — Arnar generates them from his own recipes.
- Website tester marketing REMOVED (Arnar): no seat counter he must hand-edit.
  Contact form's tester tick + proxy kept. On branch `tester-outreach`, NOT
  merged — the fold to main is Arnar's call.
- Contact + terms said myrecibook@google.com (impossible domain). Now
  myrecibook@gmail.com on BOTH main and the branch, matching CONTACT_TO_EMAIL.
- Website analytics LIVE, verified in GA4 Realtime; consent note gates the tag.
- Tags on Direction A, verified. Dark sheets lifted (unverified). Drive on prod
  DONE. App Check on Play's SHA-256, server does NOT require it.
- Offer = terms: 1,200 grant never refills, top-up 600 for $5.
- PROD LIVE: myrecibook.com + www on Cloud Run; Firestore eur3; keys in Secret
  Manager. Contact form posts to DEV on purpose.

## 🚀 Active tracks
- mvp-build — THE focus. Quota card BUILT, still awaiting Arnar's eyes. Open:
  billing seam, listing + welcome screenshots, App Check enforcement on the
  server, CLI Play publishing.
- market — open: Q2 export recon (Arnar running), Q5 steal list, Q6 cadence.
  MyFitnessPal is the diary half's real rival, and is in NO dossier.

## ⚠️ Blockers
- None open.

## 📌 Parked
- website "pocket" section promises barcode, trends and dark mode over a plain
  cookbook shot. Rebuild it around pantry + barcode shots.
- ouroboros PARKED (Arnar) — branch + worktree kept as they stand.
- consent note English-only · tag reorder has no UI · i18n paused · nutrition
  dormant · borrowed listing photos · is/sv stale money rows · stale test
  recipe_diary_chain ×1 · 34 deps outdated · serving labels ignore units · pack
  math can't reach density · audit H2/M1-M6/L1-L4 · Faroese delegate · Drive
  sign-in untested in dev app · handoff remainder · measure real usage.
