# mvp-build

**Goal:** the shippable v1 engine — extract → save → list → open, then sync and paywall.

## Done
- [x] Extraction, on-device OCR plus cloud structuring
- [x] Save: one JSON per recipe in the user's own folder
- [x] List and open
- [x] Sync connectors: Google Drive and Dropbox, both proven on the S21
- [x] Extraction proxy built

## Open
- [ ] Deploy the extraction proxy — the thin server between the app and the cloud
      vision model. It holds the API key so it never ships inside the app, and it
      counts each install's extractions against the fair-use cap. Built, running
      nowhere. Needs a host and a URL.
- [ ] Durable cap counter (currently in memory only)
- [ ] Measure real extraction usage — nothing measured yet
- [ ] Closed-test build on the Play track — Google makes a new personal developer
      account run a closed test, 12 testers for 14 unbroken days, before it will
      grant production access. So an installable alpha has to go up on Play's
      closed track well before launch.
- [ ] Billing — one-time purchase, hard paywall. Seam exists, nothing built.

## Fair-use cap
- The listing must state a number from day one, and it cannot be raised back down.
- Model pricing doubles 2027-01-01, so all cap math runs at the 2027 price.
- Strawman is 100 extractions a month. Not confirmed — needs usage data first.
- Promo codes at launch instead of a free tier.
