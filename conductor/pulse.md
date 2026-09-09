# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*
> **Updated:** 2026-09-09

## 📍 Now
- Phase: closed test, Play review PASSED. Play holds 0.20.0+42 (tag
  `the-first-0.20.0+42`). main is 0.21.0+45: release .aab built and tagged
  2026-09-09 for the closed track. Upload is BY HAND in the Play Console until
  a Play service account exists (Arnar's console); tools/publish_play.sh then
  does it — setup note in its header.
- Website carries the emulator promo set: a print under each of the six cards,
  the pocket as two phones (Stitch Slate front, Midnight behind), a Contact
  tab on the lid. Copy claims only what the app does: search is by title, the
  barcode card shows the product page a scan fills in.
- EMULATOR = SECOND HANDSET. AVD pixel_7_api_35. Binary NOT on PATH
  (~/Android/Sdk/emulator). Pin adb: ANDROID_SERIAL=emulator-5554.
  Stock: tools/seed_emulator.py --clear --photos "docs/MyReciBook Recipes
  Screenshots" --pantry-photos "docs/MyReciBook - Pantry images".
  Shoot: tools/shoot_emulator.sh → docs/MyReciBook-Emulator-Shots (light +
  dark); website/scripts/shots.mjs crops; website/scripts/render.mjs renders
  any site page to PNG, light/dark/mobile, without a browser.
- Debug builds wear a DEBUG ribbon; profile builds (dev.env) do not.
- Branch `tester-outreach` DELETED unmerged 2026-09-09 (Arnar: prune). Tip
  7a8fa5e (contact-form tester tick, onPlay price switch) recoverable by hash.
- Website analytics LIVE (GA4 Realtime); consent note gates the tag.
- Drive on prod DONE. App Check on Play's SHA-256, server does NOT require it.
  Offer = terms: 1,200 grant never refills, top-up 600 for $5.
- PROD LIVE: myrecibook.com + www on Cloud Run; Firestore eur3; keys in Secret
  Manager. Contact form posts to DEV on purpose.

## 🚀 Active tracks
- mvp-build — THE focus. Open: Play listing + welcome slide shots (shootable
  from the emulator), billing seam, App Check enforcement on the server, Play
  service account for CLI publishing.
- market — open: Q2 export recon (Arnar), Q5 steal list, Q6 cadence.
  MyFitnessPal is the diary half's real rival and is in NO dossier.

## ⚠️ Blockers
- None open.

## 📌 Parked
- grocery list unpolished (Arnar), not a gate; its header still says "planned
  recipes" · ouroboros PARKED, branch + worktree kept · consent note
  English-only · tag reorder has no UI · i18n paused (nb card 05 still says
  "9 varer"; picker hidden) · nutrition dormant · borrowed listing photos ·
  is/sv stale money rows · stale test recipe_diary_chain ×1 · 34 deps outdated
  · serving labels ignore units · pack math can't reach density · audit
  H2/M1-M6/L1-L4 · Faroese delegate · Drive sign-in untested in dev app ·
  handoff remainder · measure real usage.
