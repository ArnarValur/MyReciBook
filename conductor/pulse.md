# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-28

## 📍 Now
- Phase: build. 0.17.5+29 on main and on the phone. Branch i18n is level with 0.11.0+10 and is where language work continues.
- Build APKs ONLY via app/deploy-s21.sh — plain `flutter build apk` ships no proxy URL and placeholder connector keys.
- Cookbook is the shelf shape: untagged recipes flat, then folded tag sections (alphabetical, pantry idiom), chips row is All + Favorites only. Folds persist (cookbookOpenSections). List rows carry cover thumbnails.
- Tag editor is a full page (no drawer, no search); the recipe-page picker's New tag opens it and applies the result. Tag glyphs wear their colour everywhere; heart is tertiary everywhere.
- Diary meals live in the shelf card. Trends drops all-zero micro rows.
- Label reading: prompt demands grams for vitamins/minerals; reader drops unconverted values (vitamin >1 g, mineral >5 g per 100 g).
- Arnar's oats product file still carries 30.4 g folate from before that fix — he clears or re-reads it on the product page.
- Folder scan skips app-owned root files (RecipeStore.appOwnedFiles, tags.json) in both stores — add future app files THERE.
- Bottom-bar clearance is inset-aware: navBarClearance() in skin.dart, never a flat constant.
- bottomNavigationBar must never hold a Center — it swallows the body; tag_editor_screen_test pins it.
- Extraction server live: myrecibook-proxy, Cloud Run europe-west1. Gemini key in Secret Manager only; app/dev.env holds server URL + Drive/Dropbox keys.
- Offer in code: two weeks free, then 1200 a year. Limits 10/min, 50/day per buyer, 2000/day overall.
- Crash reporting ships ON, switch in Settings, recipe text scrubbed.
- Build 29 on the phone. Tester link still on 9. Play account live, nothing uploaded.
- Docs: pre-launch-audit-2026-08-21 · runbook-dev-deploy · gcp-project-facts. gcloud: ~/google-cloud-sdk/bin, not on PATH.
- Starter foods values UNVERIFIED vs USDA — Arnar's run; patch starter_foods.dart.
- Serving labels ignore the units pill: convertUnits touches recipe lines only, so "1 cup" shows in metric.
- Link import writes tags from the site's recipeCategory/recipeCuisine/keywords, up to 8. Review screen shows them before save.
- Full suite has not run since 2026-08-21. Everything since is per-file green only.

## 🚀 Active tracks
- mvp-build — server deployed, onboarding shipped. Billing seam open, unstarted.
- diary — meal shelf + Trends cleanup shipped. Open: product photos on diary and add-sheet cards, device verify.
- tags — cookbook shelf + full-page editor shipped, regression-tested. Open: strings are English literals, not gen_l10n keys.
- nutrition — open: grocery package-size math, serving-label conversion.
- i18n — foundation on main, language control HIDDEN until a language is finished. Open: the string sweep.

## ⚠️ Blockers
- Play grants production access only after 12 people have the app installed
  from Play's test track for 14 days straight. Arnar is recruiting testers.
- Privacy policy + Play data safety form: nothing written, blocks submission.

## 📌 Parked
- Quick add — engine real and tested, door hidden behind kQuickAddEnabled.
- Typed custom emoji for tags — left with the editor's search bar; palette of 117 remains.
- Welcome slide screenshots — Arnar's crops; drop into kSlides in slides_screen.
- Net weight off a label has nowhere to land — feeds the grocery package-size work.
- Skipped-files message: tappable list naming the files (proposed 2026-08-28, not asked for yet).
- user feedback channel · serving rescale · step ↔ ingredient chips ·
  label-photo fallback in recipes · meal names UI · copy-to-date UI ·
  row reorder · multi-barcode per image · orphan image cleanup ·
  roundup/listicle link import · accessibility pass · Dropbox production
  approval · Play key backup · audit items H2 and M1-M6 and L1-L4.
