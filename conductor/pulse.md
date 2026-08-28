# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-28

## 📍 Now
- Phase: build. 0.18.2+33 on main and on the phone. Branch i18n is level with 0.11.0+10 and is where language work continues.
- Build APKs ONLY via app/deploy-s21.sh — plain `flutter build apk` ships no proxy URL and placeholder connector keys.
- Meals are editable: Settings → Meals renames, reorders, adds/removes, and sets an optional "from HH:mm" per meal (meal_hours in settings.json). Windows wrap midnight for night shifts; today's diary shelf dots the current meal. Renames never rewrite past days.
- Pantry cold start: SafBridge.readChildFiles reads a folder's JSONs in ONE channel call (recipes use it too), AppShell warms the pantry post-frame, the tab shows a spinner then a retry on a failed first scan, ensureLoaded shares one in-flight scan.
- Index-file cache deliberately NOT built — the batch read carries 1000+ products; revisit only if a device says otherwise.
- Pantry scan row: 3/4 Scan + 1/4 "+" straight into the create screen, no barcode.
- Cookbook is the shelf shape: untagged flat, folded tag sections, chips = All + Favorites, folds persist, rows carry covers.
- Tag editor is a full page; the recipe-picker's New tag opens it. Glyphs coloured everywhere; heart tertiary.
- Diary meals live in the shelf card. Trends drops all-zero micro rows.
- Label reading demands grams for micros; reader drops unconverted values (vitamin >1 g, mineral >5 g per 100 g). Arnar's oats file still carries 30.4 g folate from before the fix — he re-reads it on the product page.
- Folder scan skips app-owned root files (RecipeStore.appOwnedFiles, tags.json) in both stores — add future app files THERE.
- Bottom bar: navBarClearance() in skin.dart, never a flat constant; bottomNavigationBar never holds a Center (tag_editor_screen_test pins it).
- Extraction server live: myrecibook-proxy, Cloud Run europe-west1. Gemini key in Secret Manager only; app/dev.env holds server URL + Drive/Dropbox keys.
- Offer in code: two weeks free, then 1200 a year. Limits 10/min, 50/day per buyer, 2000/day overall.
- Crash reporting ships ON, switch in Settings, recipe text scrubbed.
- Build 33 on the phone. Tester link still on 9. Play account live, nothing uploaded.
- Docs: pre-launch-audit-2026-08-21 · runbook-dev-deploy · gcp-project-facts. gcloud: ~/google-cloud-sdk/bin, not on PATH.
- Starter foods values UNVERIFIED vs USDA — Arnar's run; patch starter_foods.dart.
- Serving labels ignore the units pill: convertUnits touches recipe lines only.
- Link import writes tags from the site's metadata, up to 8, editable in review.
- Full suite has not run since 2026-08-21. Everything since is per-file green only.

## 🚀 Active tracks
- mvp-build — server deployed, onboarding shipped. Billing seam open, unstarted.
- diary — meal hours, pantry cold-start fix and the quarter "+" shipped. Open: product photos on diary and add-sheet cards, device verify, oats re-read.
- tags — cookbook shelf + full-page editor shipped. Open: strings are English literals, not gen_l10n keys.
- nutrition — open: grocery package-size math, serving-label conversion.
- i18n — foundation on main, language control HIDDEN until a language is finished. Open: the string sweep.

## ⚠️ Blockers
- Play grants production access only after 12 people have the app installed from Play's test track for 14 days straight. Arnar is recruiting testers.
- Privacy policy + Play data safety form: nothing written, blocks submission.

## 📌 Parked
- Quick add (kQuickAddEnabled) · typed custom emoji for tags · welcome slide screenshots · net-weight landing · skipped-files tappable list · diary day-rollover "day starts at" hour (user-request follow-on) · index-file pantry cache (the 1000+ door).
- user feedback channel · serving rescale · step ↔ ingredient chips · label-photo fallback in recipes · copy-to-date UI · row reorder · multi-barcode per image · orphan image cleanup · roundup/listicle link import · accessibility pass · Dropbox production approval · Play key backup · audit items H2 and M1-M6 and L1-L4.
