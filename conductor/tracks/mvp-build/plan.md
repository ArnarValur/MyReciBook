# mvp-build

**Goal:** the shippable v1 engine — extract → save → list → open, then sync and paywall.

## Done
- [x] Prod extraction unblocked 2026-09-10. The prod Cloud Run service
      account (283856393795-compute@) had no Firestore role; the ledger
      reserve threw, the proxy failed closed with 503 quota_unavailable, and
      prod had never completed a rescue (photo or link) since it went live.
      Arnar granted roles/datastore.user; a test call returned 200 with
      quota. Gemini key was never the problem. deploy.sh does not grant the
      role — it lives in docs/runbook-dev-deploy.md's one-time setup.
- [x] Paste-a-link door 2026-09-10 (Arnar's ask; 2a mockup: "OR FETCH FROM
      THE INTERNET · Paste a link — TikTok, IG, blog…"). ImportLink choice,
      linkIn() pulls the first http(s) link out of pasted text (same shape
      as ShareBridge), clipboard pre-fill on open, keyboard lifts the sheet,
      spent grant → cap screen like the other AI doors. app_shell routes it
      through _pushLinkReview. Tests: import_sheet_test (fake clipboard),
      shell_test (pasted link → review). Dev app only, NOT stamped.
- [x] Failed rescues → Crashlytics 2026-09-10. CrashReportingModel.
      reportRescueFailure(e, mode, host): message cut at its first colon,
      "rescue failed (link · 402 · www.allrecipes.com): the page answered
      402", non-fatal, local log always, upload only with the switch on.
      Review screen reports via context.read<CrashReportingModel?>;
      BatchModel.onFailed wired in main. First event verified in the console.
- [x] Drive redirect crash 2026-09-10. Crashlytics issue 1084a1ec (2026-09-03,
      0.20.0): FlutterActivity forwarded the OAuth VIEW intent's URI to the
      Navigator as a route. flutter_deeplinking_enabled=false in the manifest
      (bridges route every intent themselves); scrubber strips
      code/state/id_token/access_token/refresh_token query values. Unverified
      on a real Drive sign-in.
- [x] Crashlytics readable from the terminal 2026-09-10: Firebase CLI 15.30
      at ~/.hermes/node/bin/firebase, auth via gcloud ADC (stale avj.info
      login removed), GOOGLE_CLOUD_QUOTA_PROJECT=dev project, Crashlytics API
      enabled on dev, MCP server `firebase` registered in Claude Code (local
      scope). Tool parameter is appId. docs/gcp-project-facts.md.
- [x] Website promo set 2026-09-09. Eighteen emulator shots (light + dark)
      via tools/shoot_emulator.sh → docs/MyReciBook-Emulator-Shots; cropped
      by website/scripts/shots.mjs; a print under each of the six feature
      cards, the pocket section as two phones (day front, night behind), a
      Contact tab on the lid; copy trimmed to what the app does (search by
      title only; the barcode card shows the product page a scan fills in —
      the emulator camera is a test pattern). website/scripts/render.mjs
      renders any page to PNG with the colour scheme forced. Locales at key
      parity in English. Deployed to prod the same day.
- [x] Release .aab 0.21.0+45 built 2026-09-09 via app/build-release.sh,
      tagged `0.21.0+45`, and put on the closed "alpha" track from the
      terminal the same day — the first CLI publish.
- [x] Website analytics 2026-09-08. Google Analytics 4 on the prod property
      (web stream "MyReciBook Website", measurement id G-M301GKVM58 — same
      property the Android app reports into, so site and app sit in one
      dashboard). Basic consent mode: the tag is never fetched until the
      visitor accepts a note at the foot of the page, the answer lives in
      localStorage, the privacy page gained a "This website" section plus a
      control to opt in or out at any time, and withdrawing clears the GA
      cookies and reloads. New files website/app/composables/useCookieConsent.ts,
      website/app/plugins/analytics.client.ts, website/app/components/CookieNote.vue;
      id in nuxt.config runtimeConfig.public (empty string switches the whole
      feature off for a build). Copy is English-only — other locales fall back,
      and the picker is still hidden. Arnar wrote the banner wording.
      Bug that cost the session: the gtag shim pushed a plain array instead of
      the `arguments` object. Google's tag reads that queue expecting arguments
      objects and silently ignores arrays, so the script loaded with a 200,
      nothing errored, and no hit was ever sent. Tag Assistant's "deferred hits
      — no config command" was the real signal.
      Two dead ends recorded so nobody chases them again: Google's "Test
      installation" scan and the stream's "data collection isn't active"
      warning can NEVER clear on a consent-gated site, because the scanner is a
      robot that never accepts — Realtime is the only valid check; and a
      tracker blocker in the browser (Vivaldi's is a separate switch from its
      ad blocker) shows ERR_BLOCKED_BY_CLIENT, which is the visitor's machine,
      not the site. Expect the visit count to read low, never precise.
- [x] Prod infra 2026-09-01 (docs/prod-gcp-setup.md slices 1+2, minus App
      Check and Drive OAuth): website live on myrecibook.com + www via
      website/deploy-prod.sh (Cloud Run myrecibook-prod, cert, Namecheap DNS,
      old parking records deleted); prod proxy deployed and smoke-tested
      (health + model guard) with gemini-api-key (prepaid credits, tier 3)
      and brevo-api-key in prod Secret Manager; Firestore (default) eur3;
      Firebase linked, env Production; google-services-prod.json parked next
      to dev; app/prod.env (Drive client still DEV until consent verifies)
      and app/build-release.sh (swap → build .aab → restore) ready for the
      paid era. Contact form stays on the dev proxy (step 6 decision).
      Fresh-project trap logged: the compute default SA has no roles — it
      needs roles/cloudbuild.builds.builder before the first deploy.
- [x] Play app content forms, all of them, 2026-09-01: privacy URL
      https://www.myrecibook.com/privacy, sign-in "no accounts", data safety
      (collected-only: photos + user content ephemeral, crash logs +
      diagnostics, device ids required for the counter; Gemini/Crashlytics
      as processors, nothing "shared"), content rating (utility; Brazil
      14+ for IAP), target audience 18+, financial none, health = nutrition
      tracking. Store settings: Food & Drink, myrecibook@gmail.com,
      www.myrecibook.com.
- [x] Store listing drafted 2026-09-01 from the live website copy:
      docs/play-store-listing.md (short 46 chars + full description) and
      docs/MyReciBook-logo/assets/play/feature-graphic-1024x500.png (drawn
      LogoMark + wordmark on cream). Arnar filled the listing and submitted
      closed testing "Alpha" (Norway + Sweden, email-list testers) + en-GB
      listing for Play review the same night. Screenshots still owed — from
      a Play install, the dev build wears the debug banner.
- [x] Copy audit 2026-08-31 against the settled offer. Fixed: unlock tab
      "600 AI recipe rescues — fair-use cap, in writing" → "1,200 AI recipe
      rescues included" (+ its two tests); app_en.arb crash caption dropped
      "Never your recipes", which the scrubber never delivered; privacy page
      names Google Gemini as the model that structures recipe text — the same
      answer the Play data-safety form needs. Confirmed by Arnar and NOT to be
      softened: $25 is the price, cursive import is tested in English and
      Norwegian.
- [x] Website contact form, end to end 2026-08-31. POST /contact lives in the
      extraction proxy (one Cloud Run service, one Secret Manager) and never
      touches the ledger, App Check or Gemini — a message must not spend a
      rescue. Brevo transactional mail: from noreply@myrecibook.com (domain
      DKIM+DMARC authenticated at Namecheap), to myrecibook@gmail.com, visitor
      in Reply-To. Defences all re-checked server-side because a bot posting
      straight to the URL never runs the page's JavaScript: hidden honeypot
      field, 3-second fill timer, field ceilings, header-injection refusal,
      5/hour per IP, exact-origin allowlist. Traps answer 200 "sent" and mail
      nothing. 11 new tests, 41 green. Key in Secret Manager as brevo-api-key.
- [x] Terms and privacy corrected 2026-08-31: 1,200 AI recipe rescues included,
      no expiry and no yearly reset, $5 top-up, or the buyer's own Gemini key.
      Takedown clause replaces an admission about borrowed photos. The
      "recipe text scrubbed" claim removed — the scrubber strips keys, tokens,
      file names and paths, not prose.
- [x] Website language picker hidden 2026-08-31 behind showLanguagePicker in
      the layout. Locale files, routes and /is + /sv all intact for review.
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
- Evidence, cost numbers and the remaining plan: docs/archive/handoff-extraction-trim.md.

## Open
- [x] Link door + crash pipe: verified by Arnar on the dev app 2026-09-15,
      stamped 0.22.0+46, published to the closed alpha track the same day
      (publish_play.sh, edit 07513371671116569561).
- [ ] People Inc. wall (allrecipes, simplyrecipes, seriouseats → HTTP 402 to
      any non-browser fetch; Gemini url_context blocked too). Only road found:
      a hidden WebView in NetBridge that loads the page after a refusal and
      hands the HTML to LinkExtractor. ~150 lines Kotlin + a Dart fallback;
      slower, and Cloudflare may still raise a human check. Arnar's call —
      part of the "integrity of these services / backup API" talk he set for
      the next session. Meanwhile the failed state already says screenshot.
- [x] Drive sign-in verified by Arnar on the dev app 2026-09-15; rides 0.22.0+46.
- [x] First .aab on Play — internal testing release "The First - 0.20.0+42"
      live 2026-08-31 21:01. Internal track needs no forms; the 12×14d clock
      runs only in closed testing. Dev Firestore ledger wiped same evening
      for a clean tester start. Prod plan: docs/prod-gcp-setup.md.
- [x] Testers: one tester (Arnar), in through the closed opt-in link. Recruiting
      more is NOT an mvp-build item (Arnar 2026-09-03).
- [x] Handset: dev build uninstalled, installed from Play 2026-09-02.
- [x] CLOSED 2026-09-01 (Decision 1 executed, refill deleted, both proxies redeployed). Was: The offer contradicts the engine. Terms (live) say the 1,200 never
      expire and nothing resets; proxy/lib/firestore_ledger.dart:206 does a
      lazy anniversary reset and ships resets_at, which quota_counter_card.dart
      renders as "resets <date>". docs/ai-cap-mechanics.md still documents
      600/year. Arnar decides which is true, then one of the two changes.
- [x] CLOSED 2026-09-03 (proxy reason word rides ExtractionException; review + batch name all three; import_review_failed_test). Was: 429 says three different things and the app hears one. The proxy answers
      429 for rate_limited, daily_limit and cap_exceeded and sends a written
      message for each; import_review_screen.dart:148 replies "Rate-limited —
      try again shortly" to all three, so a buyer who has spent all 1,200 is
      told to wait forever. Rides the decision above.
- [x] CLOSED 2026-09-03 (promoted to the real cap-reached screen). Was: postalpha 4d "Fair-use cap reached" preview is stale: 600/600, "this
      year", "resets 1 January", no BYOK door. Debug-only, but it is the design
      source for the real screen the item above needs.
- [x] Filled Cookies card re-rescued on the new prompt — works, verified by
      Arnar's eyes (recorded 2026-09-03; said earlier, never written down).
- [ ] Handoff remainder: deterministic app-side review flags (digits but no
      qty, " each "/" or " in raw, shared line_id), regression fixtures from
      both runs, prefix-caching check.
- [x] CLOSED 2026-09-01 (privacy URL live on myrecibook.com, data safety filled, Play review passed 2026-09-03). Was: Privacy policy URL + Play data safety form. A privacy page and a terms
      page are drafted and live on the staging site (website/app/pages/
      privacy.vue and terms.vue). What is still missing: Arnar's approval of
      the wording, a public URL that is not the noindex staging one, and the
      Play data safety form itself, where five things that leave the device
      all have to be declared. Blocks submission.
- [ ] Require the app-proof check on the server once a build carrying tokens is
      on the internal track. Until then the server trusts a header the client
      invents. Sideloaded builds cannot attest — Play Integrity only vouches
      for installs that came from Play.
- [x] Play's own signing fingerprint into the App Check registration — done
      by Arnar 2026-09-03 with the app-signing certificate from Play Console
      (the upload key's fingerprint was in the field first; it never matches
      a Play install). Advanced settings left at defaults on purpose.
- [x] Debug builds install beside the Play app 2026-09-03: debug + profile
      carry the package suffix ".dev" and the label "MyReciBook dev". A second
      Android app for that package is registered in the Firebase dev project
      and google-services.json holds both clients. Proven: debug APK built and
      installed next to the Play app on the phone. Drive sign-in in the dev
      app is untested (its OAuth client is tied to the release package).
- [ ] Measure real usage. The ledger records it from the first live call;
      nothing meaningful collected yet.
- [x] Closed test on Play — review PASSED (Arnar 2026-09-03; was said in chat
      earlier, never written down). Recruiting is not an mvp-build item.
- [ ] Billing — one-time purchase, hard paywall. Seam exists, nothing built.
- [x] CLI publishing to Play 2026-09-09: tools/publish_play.sh (edit → upload
      bundle → track → commit, over the Play Developer API). Service account
      play-publisher@myrecibook-prod, key in ~/keystores/play-publisher.json,
      invited by Arnar with "release to testing tracks" + "manage testing
      tracks"; Android Developer API enabled. Track ids: internal · alpha (the
      closed test) · beta · production. Usage: tools/publish_play.sh <aab> alpha.
- [x] Play listing screenshots + welcome slide shots 2026-09-15. Eighteen
      fresh emulator shots off 0.22.0 (link door visible on the sheet);
      tools/play_shots.mjs frames eight of them as 1080×1920 store cards in
      light and dark (conductor/docs/play-listing/play/) and cuts the three
      welcome-slide tiles, light + Midnight, into app/assets/onboarding/.
      Slides wired (imageDark per feature, tiles anchored top so a wide phone
      trims the bottom); seen on the emulator through a real first run, both
      themes. Arnar uploaded the light set + a full-description change to
      the en-GB listing the same evening; in Play review. Tile crops are
      his eyes to approve. Found on the way: kAppVersion had shipped in
      0.22.0+46 still saying 0.21.0 — fixed on main, rides the next build.

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
- [x] CLOSED 2026-09-03 (counter card, sheet line, cap screen built; 0.20.0+43). Was: **Quota counter UI (app side)** — the proxy already returns the full
  `quota` object ({used, cap, grace_used, topup_balance, resets_at,
  grace_until}) in every /extract response; nothing new server-side.
  WIRED 2026-08-30, verified on device: quota parsed from every /extract and
  from 429s, cached in device.json, feeding QuotaCounterCard atop Settings.
  Honest "—" before first contact; own-key state says the counter does not
  apply; grace wording live while grace_until is in the future.
  BUILT 2026-09-03, awaiting Arnar's eyes on the dev app (0.20.0+43): one
  allowance line on the import sheet under the AI doors ("713 of 1,200
  rescues left — each import uses one"; heads-up wording from 80%; grace and
  own-key sentences), the counter card under the paywall pitch once the
  proxy has answered, the 4d preview promoted to lib/ui/cap_reached_screen
  .dart (free door first, top-up line waits for billing), the sheet's AI
  doors open that screen when the grant is spent, and the proxy's refusal
  word rides ExtractionException so the review screen and the batch queue
  say "today's limit — opens again tomorrow" / "included rescues used up"
  / "we're busy" instead of "try again shortly" for all of them. Tests:
  quota, import sheet, cap screen, review failed state, extractor reasons,
  batch captions, paywall counter. Design source: docs/ai-cap-mechanics.md §2.

## 2026-09-01 — Decision 1 executed (grant never refills)

- Engine: lazy anniversary refill deleted from InMemoryUsageLedger and
  FirestoreUsageLedger; `resets_at` gone from ReservationOutcome/toJson, the
  Firestore document writes, QuotaSnapshot and the counter card; stale
  `resetsAt` on old Firestore docs is ignored, never written again.
- Names: kDefaultYearlyCap → kDefaultIncludedCap; env INCLUDED_CAP (YEARLY_CAP
  still read as fallback); deploy.sh + README updated.
- Copy: unlock card "1,200 included — top up 600 for $5 if they ever run out"
  (test updated); en/nb/da/fi/fo terms say 600; 4d preview de-staled.
- Tests: proxy 23 green incl. new "NEVER refills — not even years later";
  app settings/batch/unlock 27 green; analyze clean both sides.
- NOT deployed: dev + prod proxies still run the refill — next deploy.sh run
  ships it. No version bump (nothing device-verified, no APK built).

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
