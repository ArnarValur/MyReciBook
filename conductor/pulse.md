# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*
> **Updated:** 2026-09-09

## 📍 Now
- Phase: closed test, Play review PASSED. Play holds 0.20.0+42 (tag
  `the-first-0.20.0+42`); main is 0.21.0+44. NO bump this session — the nav
  pill and the tag glyphs have been seen on the emulator only, never the phone.
- EMULATOR IS A SECOND HANDSET. AVD pixel_7_api_35, KVM, hw.keyboard on.
  Proven: build, install, launch, screencap, screenrecord (3 min, no audio),
  uiautomator dump, input tap. Binary NOT on PATH — ~/Android/Sdk/emulator.
  Pin adb with ANDROID_SERIAL=emulator-5554; Arnar's devices come and go.
- It is STOCKED: tools/seed_emulator.py --clear --photos "docs/MyReciBook
  Recipes Screenshots" --pantry-photos "docs/MyReciBook - Pantry images".
  12 recipes, 10 tags, 16 shelved products, ~80 diary days, daily goal 2200.
  The 26 photos are committed, so a wiped AVD is one command from stocked.
- Debug builds wear a DEBUG ribbon; profile builds do not. Marketing shots use
  a profile build with dev.env.
- Website tester marketing REMOVED (Arnar). Contact form's tester tick kept.
  On branch `tester-outreach`, NOT merged — the fold is Arnar's call.
- Website card 05 promises "9 items · from 3 planned recipes" but the meal
  planner is a placeholder. Arnar: change the words, do NOT polish the grocery
  list — it is not a launch gate.
- Website analytics LIVE, verified in GA4 Realtime; consent note gates the tag.
- Drive on prod DONE. App Check on Play's SHA-256, server does NOT require it.
  Offer = terms: 1,200 grant never refills, top-up 600 for $5.
- PROD LIVE: myrecibook.com + www on Cloud Run; Firestore eur3; keys in Secret
  Manager. Contact form posts to DEV on purpose.

## 🚀 Active tracks
- mvp-build — THE focus. Open: Play listing screenshots + welcome slide shots
  (both now shootable from the emulator), billing seam, App Check enforcement
  on the server, CLI Play publishing.
- market — open: Q2 export recon (Arnar running), Q5 steal list, Q6 cadence.
  MyFitnessPal is the diary half's real rival and is in NO dossier.

## ⚠️ Blockers
- None open.

## 📌 Parked
- website "pocket" section promises barcode, trends and dark mode over a plain
  cookbook shot. Rebuild it, plus a screenshot under each of the six cards.
- grocery list unpolished since conception (Arnar). Not a gate.
- ouroboros PARKED — branch + worktree kept as they stand.
- consent note English-only · tag reorder has no UI · i18n paused · nutrition
  dormant · borrowed listing photos · is/sv stale money rows · stale test
  recipe_diary_chain ×1 · 34 deps outdated · serving labels ignore units · pack
  math can't reach density · audit H2/M1-M6/L1-L4 · Faroese delegate · Drive
  sign-in untested in dev app · handoff remainder · measure real usage.
