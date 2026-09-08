# Relay — MyReciBook
*One entry per session, 6 lines max, newest first.*

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

## 2026-09-01 — the market gets grilled: three decisions in one sitting (Cowork)

- Shipped: market Decisions 1–3 (no refill ever + $5=600 top-up; i18n paused,
  Nordic unfreeze order; short description gains "Pay once, no subscription");
  export-recon.md checklist for Arnar's manual recon; ouroboros/vision.md
  banked — the closed food loop, NOT open, deep-dive session to come.
- Arnar: no timeline words, build order only · Q6 left open (leaning noted in
  plan) · Q5 steal order unratified — rides the ouroboros deep-dive.

## 2026-09-01 — the refill dies in code, the site learns English governs

- Shipped: Decision 1 executed — lazy refill deleted from both ledgers,
  resets_at off the wire and out of the app, unlock + 5 locale terms say
  600-for-$5, INCLUDED_CAP rename; proxy 23 + app 27 green. Translation
  sticker on non-en pages + en fallback. Housekeeping commit rode ahead.
- Arnar: English is the source of truth, sticker says English governs ·
  i18n PAUSED (Decision 2) · short description gains "Pay once, no
  subscription" (Decision 3). No version bump — nothing new on the device.
  Late adds: both proxies redeployed (no-refill live, smoke green) · testers
  proved rescue + URL on Play · CLI Play publishing agreed for next ship.
- UNFINISHED: none — dev + prod proxies both redeployed same night, smoke
  green; testers live on the no-refill ledger, rescue + URL proved on Play.

## 2026-09-01 — the release gets a tag, the website packs for four more countries

- Shipped: branch website-i18n — privacy/terms/contact/404 keyed into en.json
  (148 messages, wording verbatim), nb/da/fi/fo skeletons wired + flags,
  Gemini brief website/i18n/TRANSLATE.md + parity check, site builds clean.
- Git: tag the-first-0.20.0+42 = what Play holds; no develop branch (Arnar);
  old i18n branch deleted. Learned: internal testers don't count toward 12×14d.
- Arnar: Nordic set is is·sv·nb·da·fi·fo · he drives antigravity-cli (Gemini)
  on the branch · en/is/sv stay human-owned. No version bump — branch only.
- UNFINISHED: point antigravity-cli at website-i18n + website/i18n/TRANSLATE.md.

## 2026-09-01 — the field gets read, and it is not what the badges say

- Shipped: fourteen competitor dossiers (~90k words, two agents per app) in
  docs/competitor-research/ + _SYNTHESIS.md + recipe-app-recon.html; market
  track opened for the discussion. No code, no version bump.
- Found: none of the seven sells one-time and their users ask for it unprompted;
  displayed stars are silent-tapper averages (Mob shows 4.6, its 404 written
  reviews average 2.26); nobody pairs a cookbook with a pantry AND a diary.
- Arnar: track scope = market (research + positioning), launch stays shut.
- UNFINISHED: Q1 bounded recurring cost is the one that decides the model —
  ties to the OFFER-CONTRADICTS-ENGINE blocker. Q2–Q6 queued in the plan.

## 2026-09-01 — prod goes live in one night, every Play form falls

- Shipped: myrecibook.com + www live on prod Cloud Run (deploy-prod.sh, DNS,
  cert); prod proxy + Firestore eur3 + both keys in Secret Manager; prod.env
  + build-release.sh (google-services swap); listing texts + feature graphic
  drafted; Marco stamps on privacy/terms live.
- Broke: deploy ×2 — fresh-project bucket lag, then the compute SA lacked the
  builder role (new-GCP-project default; Arnar granted it).
- Arnar: Gemini prepay on tier 3 · target 18+ only · data safety
  collected-only · submitted closed "Alpha" (NO+SE) + en-GB listing to review.
- UNFINISHED: Play review churning · S21 Play-install + listing screenshots ·
  App Check SHA · Drive OAuth consent screen (weeks gate) — start it next.

