# Relay — MyReciBook
*One entry per session, 6 lines max, newest first.*

## 2026-09-09 — a phone that lives on the laptop

- Shipped: the emulator proven end to end — pixel_7_api_35 boots, the app builds,
  installs and launches on it, and screenshots, video, screen-reading and taps
  all work. hw.keyboard turned on. A profile APK with dev.env is built, which is
  the one without the DEBUG ribbon.
- Found: the emulator was installed all along, just missing from PATH — it sits
  at ~/Android/Sdk/emulator. A fresh emulator is empty, so seeded content is
  what stands between here and usable screenshots.
- Fixed: the welcome screen's "a oopsie" is now "an oopsie". The impossible
  myrecibook@google.com address fixed on main too, not just the branch.
- Arnar: strike the tester marketing, he will not hand-edit a seat counter · he
  is a trained chef who never cooks from recipes, so his own use of the app is
  the diary and nutrition tracking, built to escape MyFitnessPal's price · he
  will generate recipe photos rather than shoot them.
- UNFINISHED: seed the emulator with recipes, pantry and diary once the photos
  arrive, then reshoot the website's "pocket" section around pantry and barcode.
  Branch `tester-outreach` still unmerged. Four edits uncommitted on main.

## 2026-09-09 — a stocked phone on the laptop, and the bar comes off the page

- Shipped: tools/seed_emulator.py fills the emulator with a believable app —
  12 recipes, 10 tags, 16 shelved pantry products, 80 diary days, and Arnar's
  26 photos as covers. The nav pill got a shadow token and lifts off the page.
  A coverless recipe now wears its first tag's icon instead of the logo.
- Broke: the pantry rejected all 16 products — `default_serving` is an index
  into servings, not a label. The app said so plainly and that found it. An
  earlier diary averaged 900 kcal a day, which made Trends look like a
  starvation log.
- Found: the emulator was installed all along, just missing from PATH. A
  shadow cannot be added inside the pill's ClipRRect — it is clipped away with
  the child. Website card 05 promises "from 3 planned recipes"; the meal
  planner is still a placeholder, so the claim outruns the app.
- Arnar: park ouroboros, keep the branch · strike the tester marketing · tag
  icons on coverless covers, first tag only, never emoji · commit the seed
  photography so a rebuilt emulator is one command.
- UNFINISHED: Play listing screenshots and welcome slide shots — both open on
  mvp-build for weeks, both now shootable from the emulator. Then the six
  website card screenshots, the "pocket" section rebuilt around pantry and
  barcode, and card 05's copy. No version bump: the pill and the tag glyphs
  have been seen on the emulator only, never on the phone.

## 2026-09-09 — the test kitchen is struck, and a mailbox that never existed

- Shipped: the twelve-seat closed-test pitch removed from the website — wanted
  slip, RECIPE Nº 004 section, footer link, `testers` config, all strings. The
  `launch.onPlay` switch stays; the price button is a dashed "Not on Play yet"
  until the listing goes live. Contact form's tester tick untouched.
- Found: contact + terms printed myrecibook@google.com. Nobody can hold an
  @google.com address — it is Google's staff domain. Fixed to the gmail one the
  proxy has always delivered to (CONTACT_TO_EMAIL).
- Arnar: park ouroboros, keep its branch · strike the tester marketing, he will
  not hand-edit a seat counter · the "pocket" section's words do not match its
  screenshot, and pantry + barcode deserve a real showing.
- UNFINISHED: rebuild the "pocket" section around the pantry and barcode
  screenshots Arnar is gathering. Branch `tester-outreach` is unmerged — the
  fold to main is his call. Branch `agents/app-overview-and-features` is empty
  and still there; the delete was permission-blocked.

## 2026-09-08 — the website learns to count, after one wrong line of glue

- Shipped: Google Analytics 4 on myrecibook.com behind a consent note that
  blocks the tag until the visitor accepts (basic consent mode, the choice in
  localStorage, an opt-out on the privacy page, a new "This website" section).
  Deployed to prod twice; ids recorded in docs/gcp-project-facts.md.
- Broke: the gtag shim pushed a plain array instead of the `arguments` object,
  so the script loaded, nothing errored and no hit was ever sent. Tag Assistant
  said "deferred hits — no config command" and that was read as harmless.
- Learned: Google's "Test installation" scan and the "data collection isn't
  active" warning can never clear on a consent-gated site — the scanner never
  accepts. Realtime is the only valid check. Vivaldi's tracker blocker is a
  separate switch from its ad blocker and eats the tag either way.
- Arnar: banner + Google Analytics over cookieless (he wants one dashboard with
  the Android app) · wrote the banner copy himself · no version bump, website
  only, no app build.
- UNFINISHED: none — analytics verified live in Realtime the same session.

## 2026-09-03 — the tag system gets a canvas, then a rebuild the same night

- Shipped: Direction A — cookbook is one grid under a tag-tile strip, the tag
  editor is one sheet, import tags arrive as suggestions, Settings → Tags
  deleted; dark sheets + dialogs lifted a surface tier. 0.21.0+44 after his
  eyes on the dev app (checkpointed 2026-09-08 after days off).
- Broke: tile column overflowed by 6dp — the new tile test caught it.
- Arnar: chose Direction A off the canvas · dark fix scoped to sheets +
  dialogs, cards stay · next session = app work + tester outreach avenues.
- UNFINISHED: dark sheets unverified on the phone · tag reorder has no UI.

## 2026-09-03 — the debugger comes back, the counter reaches the doors

- Shipped: debug builds install beside the Play app (package suffix .dev,
  own Firebase app in the dev project); the quota card on the import sheet
  and the paywall, the real cap-reached screen, three honest 429 messages.
  0.20.0+43, debug install only.
- Found: the App Check field held the upload key's fingerprint, not Play's;
  Play's opted-in count lags a day; the Play review had passed unrecorded.
- Arnar: six style memories and both conductor commands merged onto one
  plain-English rule; the "caveman" line in the global rules replaced.
- UNFINISHED: Arnar's eyes on the quota card in the dev app.

## 2026-09-03 — the Drive gate that wasn't: prod OAuth closed in an hour

- Shipped: prod Android OAuth client on package com.merkurialstudio.myrecibook
  + Play's app-signing SHA-1, branding auto-verified, consent screen published
  to production; app/prod.env swapped off the DEV client. No version bump.
- Found: the app requests only `drive.file` — non-sensitive, so the weeks-long
  verification never applied. Play's signing cert is the fingerprint, not the
  upload key's. Internal testers do not count toward the closed test's 12.
- Arnar: mvp-build is the focus; ouroboros experiments in its worktree and
  never blocks it. Handset already moved off the dev build onto Play.
- UNFINISHED: quota card on the import sheet + paywall — not started.

## 2026-09-01 — the snake gets a track: ouroboros opens, a PoC worktree is cut

- Shipped: ouroboros track opened (plan.md D1–D7, tracks + pulse); worktree
  ../MyReciBook-ouroboros on branch `ouroboros` with PoC 1a receipt prompt +
  1b refuse-to-trust parser committed there — unwired, untested. No version bump.
- Arnar: open the track · Inventory says "an estimate, not a count" · OFF fills
  Collection + Inventory when confident, cards otherwise · scan a barcode from
  the ingredient row. D4–D7 (two-event drain, one inventory file, planner not a
  prerequisite, on-device matching) are leanings, unratified.
- Found: OffClient does barcode lookup only — receipt→OFF name search is new code.
- UNFINISHED: PoC slice one continues in the worktree from 1b's test → 1c;
  conductor files are edited on main only.

