# mvp-build

**Goal:** the shippable v1 engine — extract → save → list → open, then sync and paywall.

## Done
- [x] Extraction server DEPLOYED 2026-08-21 to Cloud Run europe-west1 (Firestore
      is the European multi-region, so a Nordic region would have been a
      cross-region hop). Verified end to end: real Gemini call, ledger
      persisted, rate limiter refusing calls past the minute limit.
- [x] Gemini key out of the app. Secret Manager only; a release build was taken
      apart and contains no key. app/dev.env carries the server URL.
- [x] google-services.json in app/android/app/ — pulled from the Firebase API,
      committed. Crash reporting and the app-proof check compile in.
- [x] Build 9 installed on a phone and uploaded to Firebase App Distribution
      for tester installs. No testers added yet.
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
      recipe text scrubbed. Ships ON 2026-08-22 (Arnar) — Settings switch turns
      it off; "Send test report" behind the version footer proves the pipe,
      non-fatal so it does not dent crash-free users.
- [x] Both import doors verified on a phone through the live server 2026-08-22
      (Arnar): screenshot rescue and URL share each fetch the recipe.
- [x] Play developer account live and verified 2026-08-21 — personal account,
      developer name **Merkurial-Studio**, contact email and phone both verified,
      website avj.info. Merchant/legal country Norway (drives Play VAT, payouts,
      and the privacy-policy jurisdiction).

## Open
- [ ] Privacy policy URL + Play data safety form. Nothing written; blocks
      submission. Five things leave the device and all must be declared.
- [ ] Require the app-proof check on the server once a build carrying tokens is
      on the internal track. Until then the server trusts a header the client
      invents. Sideloaded builds cannot attest — Play Integrity only vouches
      for installs that came from Play.
- [ ] Play's own signing fingerprint into the app-proof registration, right
      after the first upload — Play re-signs, so neither the upload nor the
      debug fingerprint covers it.
- [ ] Measure real usage. The ledger records it from the first live call;
      nothing meaningful collected yet.
- [ ] Closed-test build on the Play track — Google makes a new personal developer
      account run a closed test, 12 testers for 14 unbroken days, before it will
      grant production access. So an installable alpha has to go up on Play's
      closed track well before launch.
- [ ] Billing — one-time purchase, hard paywall. Seam exists, nothing built.

## Arnar's, not tracked here
- Spend budgets, prepay credits, API key management. He manages these. Steps
  are in docs/runbook-dev-deploy.md for reference only — do not raise them,
  list them, or treat them as blockers.

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
