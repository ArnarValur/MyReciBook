# Pulse — MyReciBook
*State only. REWRITTEN at every checkpoint, never appended. Cap 60 lines.*

## 📍 Now
- Phase: pre-project (kickoff 2026-08-20); constraint 4 amended — building
  unblocked, gates decide ship/stop (context.md §4). GATE 1 PASSED; T1 closed.
- NOW-MODE (behavioral 15–16) · checkpoint commits EVERYTHING (18) · NO
  DEAD-END SURFACES (19, new): engine-less UI hides behind flags in
  app/lib/features.dart; a container left with only duplicates is removed.
- STORAGE CREDS WIRED (2026-08-06): DRIVE_CLIENT_ID + DROPBOX_APP_KEY live in
  .env → app/dev.env (gitignored). Consoles verified on screenshots; Dropbox
  Permissions-tab submission unconfirmed. SMOKE STILL PENDING — no on-device
  connect has run yet. Drive debug SHA-1
  B8:2C:53:F7:60:EA:0B:A4:B3:CD:76:05:41:36:78:D5:93:0A:07:EB
  (project gen-lang-client-0166122901).
- HANDS-ON ROUND 1 DONE (Arnar, 2026-08-06): 7 findings → all in code same
  session except cover-image change (needs a design frame). Now in app:
  swipe-delete + Clear all (6f) on grocery · status-bar + folder-gate theme
  fixes · Favorites-only chips · collapsing hero on detail (cover scrolls
  away) · triage record docs/hands-on-triage-2026-08-06.md (partly superseded
  by the session's founder decisions).
- NAV RESHAPE (founder decisions, Arnar+Code): bar = Cookbook · Grocery ·
  Queue (badge) · Settings + FAB; 5c DRAWER REMOVED (only duplicated
  bar/Settings once dead rows hid); change-folder → system picker DIRECTLY
  (gate screen = first-run/lost-grant only; app subtree remounts keyed by
  folder). Flags off: kMealPlanEnabled (NOT cut — bet's week-two hook) ·
  kYourCopyEnabled (waits for billing 3g, lands as Settings row) ·
  kRecipeTagsEnabled.
- LATEST APK BUILT, NOT INSTALLED — S21 unplugged mid-session; Arnar back
  with the phone shortly. 315 tests, analyze clean, uncommitted-to-device.
- Turn-7 design queue: cover-image picker (own photo / pick from originals —
  Arnar's wedge; AI covers parked) · drawer removal + bar reshape to ratify ·
  collapsing hero · manual entry · edit copy · batch edges (grep DEVIATION).
- Versioning: 1.0.0 footer is a pubspec placeholder — Arnar settling
  versioning in a separate cowork session; ignore until it lands.
- Play fee: strong-build bar met in code; verdict = his hands-on pass.
  Firebase project = console home; BaaS NO; no login ever. D10: 3 free →
  ~$25 unlock. Stake ladder: 150 paid ≈ org account · ~285 ≈ MacBook → iOS.

## 🚀 Active tracks
- T3 mvp-build — hands-on round 1 folded in; next: install latest APK →
  storage smoke → Arnar verdict → fee → billing 3g.
  Plan: conductor/tracks/T3-mvp-build/plan.md
- T2 landing-page — myrecibook.com REGISTERED (Namecheap, receipt in docs/);
  live 2 Sep. Channels → docs/marketing-channels.md (5 venues; seed accounts).

## ⚠️ Blockers
- Latest build not on the phone (S21 unplugged) — one adb install away.
- Storage UNPROVEN on device: connect/sync never run. Runbook Part C =
  the smoke; failure modes in docs/storage-creds-runbook.md.
- Billing 3g ← Play fee ← Arnar's hands-on verdict.

## 📋 Next queue (sequence — no schedule)
1. Arnar plugs S21 → Code installs → poke new shell (Queue tab, swipe rows,
   change-folder, collapsing hero).
2. Storage smoke: connect Dropbox AND Drive → save recipe → files visible
   remotely → kill/reopen. Then his strong-build verdict → fee $25 →
   billing 3g.
3. Claude Design turn 7: flags above + fold turns 5–6 into the handoff.
4. Arnar off-repo: T2 landing design + 5 Gate-2 venues + seed accounts.
5. External: festival 12–16 Aug (QR, 12 testers) · 20 Aug 09:00 kickoff.

## 📌 Parked
- Proxy on Cloud Run (D2: before 11 Dec) · cap counter 4d · D9 link door ·
  inbox strip · serving-rescale · step↔ingredient chips · camera-roll nudge ·
  cover-crop tier 2 · AI-generated covers (Arnar: "later bonus if ever") ·
  telemetry (D8) · arm B ocr_dump · $2.99 top-up UNCONFIRMED · handwriting
  UNTESTED · ADR 0001 graduation due · multi-image shares one recipe · token
  store plain JSON (harden pre-prod) · storage prod errands before 11 Dec:
  Dropbox production approval + Play-signing SHA-1 on Drive client.
