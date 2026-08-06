# Pulse — MyReciBook
*State only. REWRITTEN at every checkpoint, never appended. Cap 60 lines.*

## 📍 Now
- Phase: pre-project (kickoff 2026-08-20); constraint 4 amended — building
  unblocked, gates decide ship/stop (context.md §4). GATE 1 PASSED; T1 closed.
- NOW-MODE (behavioral 15–16): queue is a sequence, no calendar framing;
  removed stays removed. Checkpoint commits EVERYTHING (behavioral 18).
- STORAGE CREDS LANDED (Arnar, 2026-08-06) — placeholder era over. `.env` +
  `app/dev.env` (both gitignored) carry DRIVE_CLIENT_ID=213431165631-p54723…
  and DROPBOX_APP_KEY=engamfq19pkgyst. Gating is per-connector
  (`placeholder-*` prefix, oauth.dart), so both wake together.
  Dropbox app: Scoped / App folder "MyReciBook" · redirect
  com.merkurialstudio.myrecibook://oauth2 · public clients ALLOW (PKCE) ·
  Development status (50 users, fine for 12 testers).
  Drive: Android client in gen-lang-client-0166122901, package
  com.merkurialstudio.myrecibook, debug SHA-1
  B8:2C:53:F7:60:EA:0B:A4:B3:CD:76:05:41:36:78:D5:93:0A:07:EB.
- ALPHA SURFACE COMPLETE (Code, 2026-08-06): no-limits run 6/6 + design
  turn 6 implemented same session. 77 → 313 tests, analyze clean, every step
  verified installed on the S21. Commits be855dd…00937bb.
- Turn 6 in code: settings 6a (segmented theme, truthful storage row,
  version-only footer until a receipt exists — drawer matched) · storage
  manage 6e (supersedes 3h post-setup; remote layout made TRUE:
  Drive MyReciBook/recipes, Dropbox /recipes) · 6f = THE destructive-confirm
  shape app-wide (survives-before-stops body; recipe delete migrated).
- Design flags remaining (grep DEVIATION in app/): manual entry · edit-mode
  copy · batch queue edges · import sheet adaptations. Newest exports:
  docs/MyReciBook Mockups.html + mockups-handoff.zip (turn 6);
  docs/design-handoff-turn6.md = the flag package that produced turn 6.
- Play fee: Arnar's strong-build bar MET in code — verdict needs his
  hands-on pass. Billing 3g + tester chain start when he calls it.
- Firebase project = console home for keys/OAuth clients; BaaS NO; no login
  ever. D10: 3 lifetime free → one-time unlock ~$25, price on landing page.
- Arnar's stake ladder: 150 paid ≈ org registration · ~285 paid = MacBook →
  iOS expansion (both far past Gate 3's bar).

## 🚀 Active tracks
- T3 mvp-build — alpha surface + turn 6 done, creds wired; next: on-device
  storage smoke → Arnar hands-on → fee → billing 3g.
  Plan: conductor/tracks/T3-mvp-build/plan.md
- T2 landing-page — myrecibook.com REGISTERED 2026-08-06 (Namecheap, WHOIS
  privacy, renews 2027-08; receipt in docs/); live 2 Sep. Channels →
  docs/marketing-channels.md (5 venues; r/androidapps DEAD; seed accounts).

## ⚠️ Blockers
- Storage UNPROVEN on device — creds are in, no connect/sync run yet. Two
  unknowns until it runs: Dropbox Permissions tab submitted (files.metadata.read,
  files.content.read, files.content.write)? · Drive consent screen published +
  SHA-1 match? Failure modes + fallbacks: docs/storage-creds-runbook.md.
- Billing 3g ← Play fee ← Arnar's hands-on verdict on the S21 build.

## 📋 Next queue (sequence — no schedule)
1. Arnar: `cd app && flutter run --dart-define-from-file=dev.env` → connect
   Dropbox AND Drive → save a recipe → files land in Apps/MyReciBook and
   MyReciBook/recipes → kill/reopen (token store held). Log to Code on failure.
2. Arnar: hands-on pass on the S21 (everything live incl. turn 6) →
   strong-build verdict → fee $25 if met → Code wires billing 3g (D10,
   license testers).
3. Arnar, Claude Design: remaining flags (manual entry, edit copy, batch
   edges) → turn 7; fold turns 5–6 into the handoff package.
4. Arnar, off-repo: T2 landing design + pick 5 Gate-2 venues + seed
   account history.
5. External: festival 12–16 Aug (QR, 12 testers) · 20 Aug 09:00 kickoff.

## 📌 Parked
- Proxy on Cloud Run (D2: before 11 Dec production) · cap counter 4d · D9
  link door · inbox strip · serving-rescale (caller-ready) · step↔ingredient
  chips · camera-roll cleanup nudge · cover-crop tier 2 · telemetry (D8) ·
  arm B ocr_dump · $2.99 top-up UNCONFIRMED · handwriting promise UNTESTED ·
  ADR 0001 graduation due · multi-image shares enter as one recipe · token
  store plain JSON (harden pre-production) · storage prod errands before
  11 Dec: Dropbox production approval + Play-signing SHA-1 on Drive client.
