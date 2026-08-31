# Pulse — MyReciBook
*State only. Rewritten at every checkpoint, never appended. Cap 40 lines.*

> **Updated:** 2026-08-31

## 📍 Now
- Phase: build. 0.20.0+42 on main, device-verified: quota counter, package-size
  math, product picker, aisle-correction delete.
- Deploy: debug build with dev.env, `adb install -r`; release APKs blocked by
  the debug signature. IDE run needs the "S21, dev key" config.
- .aab is unblocked and unbuilt: upload key at ~/keystores/myrecibook-upload.jks
  wired through android/key.properties. Command is
  `cd app && flutter build appbundle --release --dart-define-from-file=dev.env`.
- Website contact form LIVE: POST /contact on myrecibook-proxy (rev 00005),
  Brevo transactional mail, from noreply@myrecibook.com to myrecibook@gmail.com,
  visitor in Reply-To. Verified end to end 2026-08-31 — mail landed.
- Contact defences, all server-side and re-checked there: honeypot field,
  3-second fill timer, field ceilings, header-injection refusal, 5/hour per IP,
  origin allowlist. Bots get 200 "sent" and nothing is mailed. 41 proxy tests.
- Brevo: free tier 300 mails/day, myrecibook.com DKIM+DMARC authenticated at
  Namecheap. REST key in Secret Manager as brevo-api-key v2 — the one the proxy
  reads. v1 held an SMTP key Arnar deleted at Brevo 2026-08-31; it is dead.
- Website staging at rev 00010: language picker HIDDEN behind
  showLanguagePicker=false (locale files, routes, /is and /sv all intact),
  terms rewritten, contact page rebuilt with the form, privacy names Google
  Gemini as the model that structures recipe text.
- Price IS decided: $25 (Arnar 2026-08-31). Cursive import IS tested, English
  and Norwegian — both claims may stand on the site.
- Terms now: 1,200 AI recipe rescues included, no expiry, no reset, $5 top-up,
  or your own Gemini key. App's unlock tab matches.
- BYOK live in code. Open: buyers-only gate waits for billing · plaintext until
  keystore hardening · no real-key run · no tests.
- Extraction server: myrecibook-proxy, Cloud Run europe-west1; Gemini key in
  Secret Manager only; gcloud in ~/google-cloud-sdk/bin, not on PATH.
- Play: account live, app entry created, nothing configured or uploaded; entry
  must be FREE + one-time IAP.

## 🚀 Active tracks
- mvp-build — open: billing seam, data safety form, welcome screenshots, card on
  the import sheet + paywall, closed test on Play, first .aab.
- i18n — app foundation on branch, untouched; the website's picker is hidden,
  not deleted. Control stays HIDDEN until one language is done.

## ⚠️ Blockers
- Play: 12 testers × 14 days before production. Arnar recruiting.
- "Get MyReciBook" buttons (both) have no Play link yet — waiting on the store
  listing.
- Prod GCP project created 2026-08-31: MyReciBook, id `myrecibook-prod`,
  number 283856393795 (docs/gcp-project-facts.md). Nothing deployed to it yet;
  myrecibook.com not mapped.
- OFFER CONTRADICTS ENGINE: terms say nothing resets, but
  proxy/lib/firestore_ledger.dart:206 refills 1,200 every purchase anniversary
  and ships resets_at, which the counter card renders as "resets <date>".
  Arnar's call, undecided. docs/ai-cap-mechanics.md still documents 600/year.

## 📌 Parked
- nutrition dormant (Arnar 2026-08-30) — meal-plan totals need a meal plan; plan_tab.dart is a post-alpha placeholder.
- Store-listing screenshots use recipe photos found online — a complaint can pull the listing. Terms carry a takedown clause; the fix is own or licensed photos.
- Crash scrubber strips keys, tokens, file names and paths — NOT recipe prose. Site copy and app_en.arb corrected 2026-08-31; the scrubber itself unchanged.
- 429 means three different things (per-minute, per-day, cap spent) and import_review_screen.dart:148 says "try again shortly" to all three — a buyer at the cap is told to wait forever. Proxy already sends the right message and the app drops it.
- postalpha 4d "Fair-use cap reached" preview still says 600/600, "this year", "resets 1 January"; no BYOK door. Debug-only, but it is the design source for the real screen.
- Stale tests, lib right: cookbook_view ×2 (docs/test-comb-2026-08-29.md) · recipe_diary_chain "linking one ingredient" · shell_test ×2 ("Where your recipes live", "This phone") — found failing 2026-08-31.
- Dependency bump parked to a pre-release session: 34 outdated.
- serving labels ignore the units toggle · grocery pack math cannot reach the density table.
- share-a-copy invite text + PDF footer breadcrumb · quick add · typed custom emoji · net-weight landing · skipped-files list · day-rollover hour · index-file pantry cache · postalpha preview paints the old move-sheet mock · categoryCounts unused but still tested.
- feedback channel · serving rescale · step ↔ ingredient chips · copy-to-date UI · row reorder · multi-barcode · orphan image cleanup · listicle import · accessibility pass · Dropbox approval · Play key backup · audit H2, M1-M6, L1-L4 · website OG per-page images · is/sv translations await Arnar and Höddi.
