# mvp-build

**Goal:** the shippable v1 engine — extract → save → list → open, then sync and paywall.

## Done
- [x] Extraction, on-device OCR plus cloud structuring
- [x] Save: one JSON per recipe in the user's own folder
- [x] List and open
- [x] Sync connectors: Google Drive and Dropbox, both proven on the S21
- [x] Extraction proxy built
- [x] Proxy hardened 2026-08-21 (audit B1-B3): Firestore ledger replaces the
      in-memory count, App Check via Play Integrity verified server-side behind
      a flag, per-bucket limits 10/min and 50/day, global breaker 2000/day,
      slot reserved before Gemini and refunded on failure. 30 tests green.
- [x] App Check registered in Firebase for com.merkurialstudio.myrecibook,
      upload + debug fingerprints added (Arnar, 2026-08-21).
- [x] Firestore (default) database created on MyReciBook-Dev (Arnar, 2026-08-21).
- [x] Crash reporting wired: local ring buffer always, Crashlytics on consent,
      recipe text scrubbed. Default OFF — flipping it is Arnar's open call.
- [x] Play developer account live and verified 2026-08-21 — personal account,
      developer name **Merkurial-Studio**, contact email and phone both verified,
      website avj.info. Merchant/legal country Norway (drives Play VAT, payouts,
      and the privacy-policy jurisdiction).

## Open
- [ ] Deploy the extraction proxy. Code and deploy.sh are ready; gcloud is not
      installed on PlutoII, so it has never run against a live project. Every
      manual step is in docs/runbook-dev-deploy.md.
- [ ] google-services.json into app/android/app/ — a Firebase Console download.
      Until it lands, builds have no Crashlytics and send no App Check token.
- [ ] Flip APP_CHECK_ENFORCE once a token-carrying build is on the internal
      track. Until then the proxy trusts a header the client invents.
- [ ] Play App Signing SHA-256 into App Check, right after the first upload —
      Play re-signs, so neither the upload nor debug fingerprint covers it.
- [ ] Privacy policy URL + Play Data Safety form. Nothing written; blocks
      submission. Five things leave the device and all must be declared.
- [ ] Measure real extraction usage — nothing measured yet. The ledger records
      it from the first deployed call.
- [ ] Closed-test build on the Play track — Google makes a new personal developer
      account run a closed test, 12 testers for 14 unbroken days, before it will
      grant production access. So an installable alpha has to go up on Play's
      closed track well before launch.
- [ ] Billing — one-time purchase, hard paywall. Seam exists, nothing built.

## Fair-use cap
- The listing must state a number from day one, and it cannot be raised back down.
- Model pricing doubles 2027-01-01, so all cap math runs at the 2027 price.
- Working number is 1200/year ("100 a month"), in code as kDefaultYearlyCap.
  Not confirmed — needs usage data first. Promo codes at launch, not a free tier.
- The offer, confirmed by Arnar 2026-08-21: **first two weeks free, then 1200
  over the year.** kGraceDays 14, kGraceCeiling 300, kDefaultYearlyCap 1200.
- Free spending is recorded in graceUsed — free is not unmeasured. Total usage
  is always graceUsed + used.
- Spend-rate governor added on Arnar's catch: 50/bucket/day, applied during the
  free fortnight too, so nobody drains the offer or a year in an afternoon.
  It says "not today", never "never".
- When billing lands: seed graceUntil from Google's purchaseTimeMillis, or a
  reinstall restarts the free fortnight.
