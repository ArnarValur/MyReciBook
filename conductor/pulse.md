# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-30

## 📍 Now
- Phase: build. 0.19.0+39 on main; branch i18n at 0.11.0+10. No bump this
  session — counter/BYOK await device verify.
- Phone currently carries a DEBUG install (Arnar's IDE session) — a release
  APK won't install over it (signature mismatch); uninstall or IDE-run.
- APKs ONLY via app/deploy-s21.sh — plain `flutter build apk` ships no proxy
  URL and placeholder connector keys. docs/runbook-dev-deploy.md §5.
- Quota counter: QuotaCounterCard atop Settings — bar, "N of 1,200 requests
  left", demo numbers, unwired to the proxy's quota object yet.
- BYOK live in code (Arnar's go): key via cog dialog on the card →
  device.json (never rides backup), flips every AI call to direct Gemini on
  the user's key, no cap UI in BYOK mode. Open: buyers-only gate waits for
  billing seam (today everyone sees it) · plaintext until keystore
  hardening · no real-key run · no tests.
- Top-up decided: +1200 rescues, $5 flat, never expires (ai-cap §5).
- Extraction v2 live on +39. Arnar's re-rescue of the Filled Cookies card
  pending — run variance on prose sections is the watch item.
- Extraction server live: myrecibook-proxy, Cloud Run europe-west1. Gemini
  key in Secret Manager only; app/dev.env holds URL + connector keys.
- gcloud lives in ~/google-cloud-sdk/bin, not on PATH.
- Offer in code: pay once; AI grace two weeks free, then 1200/year. Limits
  10/min, 50/day, 2000/day overall. Price tag NOT decided ($25 placeholder).
- Play: account live, nothing uploaded; entry must be FREE + one-time IAP.
- Test comb docs/test-comb-2026-08-29.md — repairs proposed, Arnar
  undecided. cookbook_view ×2 still red (stale asserts, lib right).
- Cadence: analyze between changes → touched files warm → full suite at
  bedtime. KGP warning (firebase_app_check, mobile_scanner): bump when
  migrated versions land, nothing now.
- website/ — Nuxt 4 landing, en + is + sv drafts; Icelandic awaits Arnar's
  rewording, Swedish awaits Höddi. privacy/terms/contact/404 still English.
  Staging (noindex) redeployed 2026-08-30 with both languages.

## 🚀 Active tracks
- mvp-build — counter card + BYOK in code. Open: quota feed, billing seam,
  privacy policy, data safety form, welcome screenshots, card re-rescue.
- diary — open: device verify · oats label re-read · starter_foods vs USDA.
- tags — open: strings are English literals.
- nutrition — open: grocery package-size math, serving-label conversion.
- i18n — foundation on branch i18n; control HIDDEN until one language done.

## ⚠️ Blockers
- Play: 12 testers × 14 days before production. Arnar recruiting; app entry
  + merchant profile not created in Play Console.
- Privacy policy + data safety form: website draft awaits Arnar's approval.

## 📌 Parked
- share-a-copy invite text + PDF footer breadcrumb (Arnar's session) · quick add · typed custom emoji · net-weight landing · skipped-files list · day-rollover hour · index-file pantry cache.
- feedback channel · serving rescale · step ↔ ingredient chips · label-photo fallback · copy-to-date UI · row reorder · multi-barcode · orphan image cleanup · listicle import · accessibility pass · Dropbox approval · Play key backup · audit H2, M1-M6, L1-L4 · website OG per-page images.
