# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-30 (late)

## 📍 Now
- Phase: build. 0.20.0+42 on main. Everything in it is verified on the device:
  quota counter, package-size math, product picker, aisle-correction delete.
- Deploy: debug build with dev.env, `adb install -r`. Release APKs blocked by
  the debug signature. IDE run needs the "S21, dev key" config; the "no key"
  one builds a keyless app and every rescue fails.
- Quota counter: proxy count parsed on extract and on 429, cached in
  device.json, atop Settings. Never-contacted shows "—". Grace rescues sit in
  their own counter, so 0/1,200 during the fortnight is correct.
- Package-size math: linked row reads "750 g Flour · 2 × 500 g". Silent below
  2 packs, on bare numbers, worded sizes, cups vs a weight pack.
- Product picker on the shared collapsible shelf; category_chips.dart deleted.
  Folds reset each open, typing flattens to a hit list.
- Aisle corrections deleted (Arnar 2026-08-30). Grouping and merges stay; old
  saved corrections ignored on read, rows in a custom aisle keep it.
- BYOK live in code: cog dialog → device.json key, flips AI calls to direct
  Gemini. Open: buyers-only gate waits for billing · plaintext until keystore
  hardening · no real-key run · no tests.
- Offer in code: pay once; AI grace two weeks, then 1200/year. Limits 10/min,
  50/day, 2000/day. Price NOT decided ($25 placeholder). Top-up decided:
  +1200 rescues, $5 flat, never expires (ai-cap §5).
- Extraction server: myrecibook-proxy, Cloud Run europe-west1. Gemini key in
  Secret Manager only; app/dev.env holds URL + connector keys. gcloud lives in
  ~/google-cloud-sdk/bin, not on PATH.
- Play: account live, nothing uploaded; entry must be FREE + one-time IAP.
- Dependency bump parked to its own pre-release session: 34 outdated; real
  jumps google_fonts 6→8, qr 3→4, code_assets 1→2.
- Test comb docs/test-comb-2026-08-29.md — repairs proposed, Arnar undecided.
  cookbook_view ×2 still red (stale asserts, lib right).
- website/ — Nuxt 4 landing, en + is + sv drafts; is awaits Arnar, sv awaits
  Höddi. privacy/terms/contact/404 English. Staging noindex, live.

## 🚀 Active tracks
- mvp-build — open: billing seam, privacy policy, data safety form, welcome
  screenshots, card on the import sheet + paywall, closed test on Play.
- nutrition — open: manual product entry, meal totals, density table.
- i18n — foundation on branch; control HIDDEN until one language done.

## ⚠️ Blockers
- Play: 12 testers × 14 days before production. Arnar recruiting; app entry +
  merchant profile not created in Play Console.
- Privacy policy + data safety form: website draft awaits Arnar's approval.

## 📌 Parked
- share-a-copy invite text + PDF footer breadcrumb (Arnar's session) · quick add · typed custom emoji · net-weight landing · skipped-files list · day-rollover hour · index-file pantry cache · postalpha preview still paints the old move-sheet mock · categoryCounts unused but still tested.
- feedback channel · serving rescale · step ↔ ingredient chips · label-photo fallback · copy-to-date UI · row reorder · multi-barcode · orphan image cleanup · listicle import · accessibility pass · Dropbox approval · Play key backup · audit H2, M1-M6, L1-L4 · website OG per-page images.
