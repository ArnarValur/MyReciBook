# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*
> **Updated:** 2026-09-09

## 📍 Now
- Phase: closed test, Play review PASSED. Play holds 0.20.0+42. main is
  0.21.0+45: release .aab built + tagged 2026-09-09 for the closed track.
  Upload is BY HAND until a Play service account exists (Arnar's console);
  tools/publish_play.sh then does it — setup note in its header.
- Website carries the emulator promo set: a print under each of the six
  cards, the pocket as two phones (day front, night behind), a Contact tab.
  Copy claims only what the app does (search by title; barcode card = the
  product page a scan fills in).
- EMULATOR = SECOND HANDSET (pixel_7_api_35; binary off PATH at
  ~/Android/Sdk/emulator; adb pinned to ANDROID_SERIAL=emulator-5554).
  Stock: tools/seed_emulator.py --clear --photos "docs/MyReciBook Recipes
  Screenshots" --pantry-photos "docs/MyReciBook - Pantry images". Shoot: tools/
  shoot_emulator.sh · crop: website/scripts/shots.mjs · render: website/scripts/
  render.mjs. Profile builds (dev.env) wear no DEBUG ribbon.
- Branch `tester-outreach` DELETED unmerged (Arnar: prune); tip 7a8fa5e recoverable.
- PROD LIVE: myrecibook.com on Cloud Run, Firestore eur3, keys in Secret
  Manager, GA4 behind a consent note, Drive OAuth done. App Check registered,
  server does NOT require it. Contact form posts to DEV on purpose.
  Offer = terms: 1,200 grant never refills, top-up 600 for $5.

## 🚀 Active tracks
- mvp-build — THE focus. Open: Play listing + welcome slide shots (emulator),
  billing seam, App Check enforcement on the server, Play service account.
- market — open: Q2 export recon (Arnar), Q5 steal list, Q6 cadence. MyFitnessPal
  is the diary half's real rival; it is in NO dossier.

## ⚠️ Blockers
- None open.

## 📌 Parked
- grocery list unpolished (Arnar), not a gate; its header says "planned
  recipes" · ouroboros PARKED, branch + worktree kept · consent note
  English-only · tag reorder has no UI · i18n paused (nb card 05 stale;
  picker hidden) · nutrition dormant · borrowed listing photos · is/sv stale
  money rows · stale test recipe_diary_chain ×1 · 34 deps outdated · serving
  labels ignore units · pack math can't reach density · audit H2/M1-M6/L1-L4
  · Faroese delegate · Drive sign-in untested in dev app · handoff remainder
  · measure real usage.
