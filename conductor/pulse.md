# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-30 (late)

## 📍 Now
- Phase: build. 0.20.0+42 on main, all of it device-verified: quota counter,
  package-size math, product picker, aisle-correction delete.
- Deploy: debug build with dev.env, `adb install -r`; release APKs blocked by
  the debug signature. IDE run needs the "S21, dev key" config — "no key"
  builds a keyless app and every rescue fails.
- Nutrition audited against the code 2026-08-30 and found COMPLETE: density
  table, per-serving calculator, recipe badge, product edit page, manual
  product entry, label photo, package-size math — real, tests pass.
- Quota counter: proxy count parsed on extract and on 429, cached in
  device.json, atop Settings. "—" before first contact; grace rescues have
  their own counter, so 0/1,200 during the fortnight is correct.
- BYOK live in code: cog dialog → device.json key, AI calls go direct to
  Gemini. Open: buyers-only gate waits for billing · plaintext until keystore
  hardening · no real-key run · no tests.
- Offer in code: pay once; AI grace two weeks, then 1200/year; 10/min, 50/day.
  Price NOT decided ($25 placeholder). Top-up: +1200 rescues, $5, never
  expires (ai-cap §5).
- Extraction server: myrecibook-proxy, Cloud Run europe-west1; Gemini key in
  Secret Manager only, dev.env holds URL + connector keys; gcloud in
  ~/google-cloud-sdk/bin, not on PATH.
- Play: account live, nothing uploaded; entry must be FREE + one-time IAP.
- Dependency bump parked to a pre-release session: 34 outdated (google_fonts
  6→8, qr 3→4, code_assets 1→2).
- Stale tests, lib right in all three: cookbook_view ×2 (docs/test-comb-2026-
  08-29.md) and recipe_diary_chain "linking one ingredient" — taps a product
  in the picker, which opens folded since the shelf rework.
- website/ — Nuxt 4 landing, en live + is/sv drafts (is awaits Arnar, sv awaits
  Höddi); privacy/terms/contact/404 English; staging noindex.

## 🚀 Active tracks
- mvp-build — open: billing seam, privacy policy, data safety form, welcome
  screenshots, card on the import sheet + paywall, closed test on Play.
- i18n — foundation on branch; control HIDDEN until one language done.

## ⚠️ Blockers
- Play: 12 testers × 14 days before production. Arnar recruiting; app entry +
  merchant profile not created in Play Console.
- Privacy policy + data safety form: website draft awaits Arnar's approval.

## 📌 Parked
- nutrition dormant (Arnar 2026-08-30) — built out; its last item, meal-plan totals, needs a meal plan, and plan_tab.dart is a post-alpha placeholder.
- serving labels ignore the units toggle (pantry/diary never call convertUnits) · grocery pack math cannot reach the density table, so cups vs a weight pack stay silent.
- share-a-copy invite text + PDF footer breadcrumb (Arnar's session) · quick add · typed custom emoji · net-weight landing · skipped-files list · day-rollover hour · index-file pantry cache · postalpha preview still paints the old move-sheet mock · categoryCounts unused but still tested.
- feedback channel · serving rescale · step ↔ ingredient chips · copy-to-date UI · row reorder · multi-barcode · orphan image cleanup · listicle import · accessibility pass · Dropbox approval · Play key backup · audit H2, M1-M6, L1-L4 · website OG per-page images.
