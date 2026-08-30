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

## Onboarding — shipped 2026-08-27 (0.12.0 → 0.14.0)
- First run: welcome → first-time setup (folder, units, theme, optional
  Drive/Dropbox connect) → feature slides → app. Built from Arnar's Claude
  Design mockup, docs/MyReciBook Flutter welcome-mockups.zip turn 1.
- Onboarding is VERSIONED, not a bool: kOnboardingVersion vs the marker in
  device.json. Bump it after a release and the slides replay as a what's-new.
- A lost SAF grant still goes straight to the re-pick gate — that user has an
  app, they lost a permission, and setup again would be theatre.
- Slide screenshots pending Arnar's crops: kSlides in ui/onboarding/slides_screen.
- Fixed the same day: tree_uri lived in settings.json, which rides Android
  cloud backup and D2D, so a restored install was handed a folder path it had
  no grant for and met "your recipes folder moved" as its FIRST screen. Moved
  to app-support/device.json, excluded in both res/xml rule files; a pre-split
  settings.json is drained on load so nobody loses their folder on update.

## Rescue flow polish — shipped 2026-08-30 (0.18.3 → 0.19.0+37)
- Status bar: rbStatusBarAnchor as both MaterialApps' builder — every route
  inherits theme-correct icons; dark screens (originals viewer, barcode scan)
  still override locally. The photo picker used to leave white icons on cream.
- Review header Retry confirms first (re-extract spends a rescue and wipes
  edits); the failed screen's "Try again" stays direct.
- Cover card always on the review form: own photo via camera/gallery beats a
  link import's photo; ✕ clears back to the link cover or none.
- times.extra in schema + prompt + file: Refrigerate/Rise/Marinate… as
  {label, min}, omitted when empty so old files round-trip byte-identical.
- Rendering: per-part chips on review and detail (value-gated), total-first on
  cookbook cards, RecipeTimes.compactLine() for PDF/Docs export.
- Row editor: one labeled pill per part, add-time sheet (suggestions +
  custom), ✕ removes; untouched times ride through verbatim, touched saves
  rebuild every field AND raw so raw never lies. Unit flip converts
  (270 min → 4,5 hr, never 270 hr); prefill picks clean half-hours.
- Detail hero: tap zooms only the face shown — the flip pill is the one door
  to the screenshots viewer.
- Seam tests added: import → save → edit → save (edit_recipe_test ×2), pill
  conversion/prefill (editor_fields_test), extra + compactLine round-trip
  (recipe_roundtrip_test).

## Extraction prompt v2 — shipped 2026-08-30 (0.19.0+38/+39)
- Model now gets trimmed assets/extract.schema.json, not the file schema — no
  more invented uuids/timestamps/model names (both AI Studio runs fabricated
  them). App fills those fields itself after the call.
- One written line → several ingredients: line_id through prompt, file format
  (Ingredient.lineId, absent-unless-set so old files round-trip byte-identical)
  and review screen — the line renders once, parsed children beneath, one
  confirm clears the whole line.
- Confidence is buckets (certain/probable/guess); GeminiExtractor.normalizeContent
  folds them to 1.0/0.6/0.3 and derives overall from the worst line, so the
  batch 0.8 auto-save bar holds any non-certain recipe. Labels path untouched.
- item is normalised spelling now (raw "cream of tarter" → item "cream of
  tartar", rule 4); prose sections extract both ways (rule 6) after the phone
  run ate the Filling paragraph as ingredient raws and left 1 step.
- Evidence, cost numbers and the remaining plan: docs/handoff-extraction-trim.md.

## Open
- [ ] Re-rescue the Filled Cookies card on +39 — prose rule and split-line
      grouping unverified by Arnar's eyes; run variance is real.
- [ ] Handoff remainder: deterministic app-side review flags (digits but no
      qty, " each "/" or " in raw, shared line_id), regression fixtures from
      both runs, prefix-caching check.
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
- [ ] Closed test on Play — Google grants a new personal developer account
      production access only after 12 people have the app installed from the
      test track for 14 days straight. Nobody recruited; Arnar owns that.
      Nothing to do with the 14 free days a buyer gets — same number, unrelated.
      An installable alpha has to be on the closed track well before launch.
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
- Top-up decided 2026-08-30 (Arnar): **+1200 rescues, $5 flat, never expires.**
  One pack, round number, no .99 pricing. Details + guard rail in
  docs/ai-cap-mechanics.md §5; scratchpad has the math.
- [ ] **Quota counter UI (app side)** — the proxy already returns the full
  `quota` object ({used, cap, grace_used, topup_balance, resets_at,
  grace_until}) in every /extract response; nothing new server-side.
  STARTED 2026-08-30: QuotaCounterCard atop Settings (bar + "N of 1,200
  requests left", cog → BYOK dialog) — demo numbers, unwired. Remaining:
  cache the latest quota from each response and feed the card, show it on
  the import sheet + paywall,
  "Uses 1 of your 1,200" line before AI paths, grace-window wording ("still in
  your free two weeks") while grace_until is in the future, distinct
  daily-limit message (never confuse the 50/day governor with the cap), two
  nudges only (~80% and empty; empty leads with "Type it in — always free"
  before the $5 top-up). Promote the 4d preview screen when this lands.
  Design source: docs/ai-cap-mechanics.md §2.

## Parked — post-launch
- **BYOK (bring your own key)** — agreed 2026-08-30; BUILT same day on
  Arnar's "proceed" (unparked from post-launch): key in device.json via
  ByokModel (never rides backup), GeminiExtractor byokKey supplier flips
  every AI call (rescue, link fallback, label read) to direct Gemini on the
  user's key, save/replace/remove dialog behind the counter card's cog with
  the plain-words free-tier training warning. OPEN: buyers-only gate waits
  for the billing seam (today every install sees it) · key plaintext until
  the pre-prod keystore hardening (tokens.json stance) · no on-device run
  with a real user key yet · no BYOK test coverage.
  Original rationale — the extractor's direct-Gemini transport already exists
  (dev mode); BYOK points it at a user-entered key. The old F3 rule ("public
  build must never ship a key") was about OUR key in the APK — a user's own
  key is theirs, on their device, their bill. BYOK users cost us $0 and exit
  the fair-use counter entirely. Three guard rails, all required:
  1. Privacy warning in plain words on the settings screen: Google's FREE
     Gemini tier trains on what you send, the paid tier doesn't — a BYOK
     user's screenshots run under their key's terms, not ours.
  2. Behind the unlock — a buyer's perk, never a free-tier backdoor. No cap
     UI in BYOK mode; their Google console is their meter.
  3. Key in Android encrypted storage, excluded from backups, sent nowhere
     but Google.
  Placement: "Advanced" in settings, never marketed, never in the listing.
  Known cost: "my key doesn't work" support mail — low-key placement keeps
  it rare.
