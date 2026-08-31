# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-31 (evening 2)

## 📍 Now
- Phase: first testers. "The First" 0.20.0+42 LIVE on Play internal testing
  since 2026-08-31 21:01 — first .aab ever (74 MB bundle, 15 MB install),
  upload-key signed, dev.env; temporary app name until listing review.
- Internal track = no forms, 100 testers max. The 12×14d clock runs only in
  CLOSED testing. Plan: internal now (Arnar + Höddi), closed when recruited.
- Play next: Testers tab (two Gmails, invite link to Höddi) → app setup forms.
- S21: Play build signature differs — uninstall dev app first; folder grant +
  settings reset, recipes in the user folder survive.
- Prod plan: docs/prod-gcp-setup.md. Slice 1 = website onto myrecibook-prod +
  map myrecibook.com (gives the privacy URL Play needs). Slice 2 = prod
  proxy/Firestore/Firebase, only before anyone pays; testers stay on dev.
- Dev Firestore wiped 2026-08-31 (quota+control, 6 docs, all already 1200),
  verified empty. gcloud on PATH via ~/.zshrc now.
- .aab command: `cd app && flutter build appbundle --release
  --dart-define-from-file=dev.env`. Debug: `adb install -r` + dev.env.
- Extraction proxy: Cloud Run europe-west1, dev project; contact form live on
  it (Brevo). Website staging rev 00010: picker hidden, terms 1,200 no reset,
  privacy names Gemini. Price $25. BYOK live, ungated until billing.

## 🚀 Active tracks
- mvp-build — open: Play app setup forms, store listing, website→prod for the
  privacy URL, testers invited, billing seam, card on import sheet + paywall,
  welcome screenshots, closed test when ~12 recruited.
- i18n — app foundation on branch, untouched; website picker hidden, not
  deleted. Control stays HIDDEN until one language is done.

## ⚠️ Blockers
- Closed testing needs a public privacy URL → website to prod is next
  session's work (plan slice 1).
- Drive OAuth on prod: consent verification can take WEEKS — start early
  (plan item 16). 12 testers × 14 days before production; Arnar recruiting.
- "Get MyReciBook" buttons linkless — waiting on the store listing.
- OFFER CONTRADICTS ENGINE: terms say nothing resets, firestore_ledger.dart:206
  refills 1,200 on the purchase anniversary and the card renders "resets
  <date>". Undecided. The 429 triple-meaning message bug rides with it.

## 📌 Parked
- nutrition dormant · borrowed listing photos (takedown clause) · crash
  scrubber strips keys/paths not prose · postalpha 4d preview stale (600) ·
  stale tests cookbook_view ×2 + recipe_diary_chain ×1 + shell ×2 · 34 deps
  outdated · serving labels ignore units toggle · pack math can't reach
  density table · audit H2/M1-M6/L1-L4 · is/sv translations await the two.
