# Relay — MyReciBook
*One entry per session, newest last, ≤10 lines, plain language.
Past 12 entries: trim to newest 8, archive to conductor/pulse-archive/relay-pre-{date}.md.*

## 2026-08-06 (late) — first REAL import passed on the S21 · cover idea parked
- Arnar ran the app for real: extract → edit → save worked, and add-screenshot
  pulled the method in — "comes out pretty well for the bare ui". T3 step 4 ✔.
  The whole engine slice is now proven end-to-end on the actual device.
- Idea parked (Arnar's, not built): auto-detect + crop the recipe cover photo.
  Two tiers in pulse 📌 — free BoxFit.cover of screenshot 1 at skin time; AI
  bbox crop only if the Gate-1 spike proves it (same call, no extra cost).
- Next session: UI-heavy — Arnar brings many screens and new layouts; agent
  pairs the skin onto the proven flows, then share-sheet + SAF store (arch §8).

## 2026-08-06 (all-nighter, skin) — all 12 hi-fi screens built · skin live on the S21
- What happened: Arnar's Claude Design project landed (DittoDatto design system,
  full handoff spec → docs/design/handoff.md). One session built the whole set:
  tokens → theme (light+dark), shared skin primitives, alpha screens wired on
  the proven flows (import sheet · review with confirm chips · cookbook grid
  with screenshot covers · detail with provenance flip + favorite heart · cook
  mode with wakelock+timer), and the five post-alpha screens (batch, paywall,
  storage, grocery, cap) as debug-gallery previews. Fonts bundled offline-safe
  (rule 8); schema gained the agreed favorite bool. 77 green → APK on the S21,
  skin verified rendering with Arnar's real recipe. Review-note catches all in.
- For Arnar: open the app — it looks like your mockups now. Long-press the
  wordmark for the post-alpha previews. Next session: share-sheet + SAF.
- Deep doc: docs/design/skin-implementation-map.md — every deviation + why,
  where each screen lives, test-contract changes, post-alpha wiring points.

## 2026-08-06 (eve→night, cowork) — arm A in-app · blitz · money + infra rounds
- Arnar challenged the spike protocol — right, it predated the app. T1 D5:
  arm A judged in-app (y/n at review BEFORE edits); harness = tuning fallback;
  unit = recipes/rows (8 more → 10). Arm B unchanged.
- Blitz (constraint 4 as amended): 4 Code nights — SAF → grocery 4a → batch
  3b+manual → settings+D9; billing joins IF the fee lands Fri (Arnar's offer).
  Fri = closed-test-complete; account = PERSONAL (no org nr) → 12×14 stands,
  festival = tester QR.
- T3 D10 on delegated call: 3 lifetime free imports → one-time unlock, ~$25
  anchor, price ON the landing page. Dashboard = Play Console (nothing to
  host). Gemini project now TIER 3 POSTPAY (cap task queued). Proxy home:
  Cloud Run beside Gemini, service identity — supersedes CF rec. Firebase: no.
- Arnar's stake: 150 buyers ≈ 30k NOK ≈ funds his formal org. Learned:
  hyperfocus etiquette (no clock talk, banked stays banked) — behavioral
  candidate, needs his explicit yes next session.
- Next: Code night 1 = SAF (firing); fee Fri if strong; Gate 1 target: w/e.

## 2026-08-06 (day, cowork) — T2 channel research (deep-research + verify)
- Where MyReciBook gets seen: full playbook → docs/marketing-channels.md.
  Gate-2 five: r/SideProject · r/alphaandbetausers · FB answer-posting
  (Declutter 365 / Grandma's Secret Recipes / Instant Pot) · r/Cooking
  comments · XDA beta post. BetaList $39 optional; $100 ads = skip (noise).
- Verification killed: r/androidapps (bans ALL self-promo + tester asks),
  r/ADHD, Product-Hunt-as-install-driver. Beckman = 616K subs, Dec series real.
- Launch pitches: Beckman → Android Police (Jon Gilbert; ReciMe screenshot
  import reported broken May 2026 = the angle) → AA Walker → Show HN local-first.
- Bet scope: "can't follow me" = Crouton/Mela/Pestle only; ReciMe wedge =
  pay-once + working screenshot import + owned files (doc §7).

## 2026-08-06 (night→dawn, Code) — no-limits run complete: 6/6 items, 77 → 309 tests
- The whole remaining alpha surface landed in one run, each item built,
  adversarially reviewed, tested, and verified installed on the S21:
  SAF store + share-sheet · grocery engine + nav shell (bar + 5c drawer) ·
  saved-recipe edit (D6 am.) · storage connect 3h (Drive+Dropbox, full on
  placeholder creds) · batch 3b + manual entry · settings (minimal, flagged).
- For Arnar: your strong-build bar is met on paper — the verdict is a
  hands-on pass on the phone. Creds spec + debug SHA-1 are in chat; two
  dev.env lines activate storage. ~15 DEVIATION flags await your design turn.
- Next: your review → fee call → billing 3g. Code queue otherwise empty.

## 2026-08-06 (dawn, Code) — design turn 6 in code · creds next session
- Arnar's turn 6 landed and was implemented same session: settings 6a
  (segmented theme, truthful storage row, footer drops "you own this copy"
  until a receipt exists), storage manage 6e (remote layout changed to make
  the designed MyReciBook/recipes label TRUE), 6f extracted as the one
  destructive-confirm shape app-wide (recipe delete migrated to it).
- Ratified flags retired; still undesigned: manual entry, edit-mode copy,
  batch edge states. 313 tests, verified on the S21. Commit 00937bb.
- Checkpoint rule hardened after Arnar's correction: commit EVERYTHING,
  always (behavioral 18) — this checkpoint stages the full tree.
- Next: Arnar hands-on → fee verdict; storage creds arrive next session.

## 2026-08-06 (Code) — storage creds wired: Drive + Dropbox out of placeholder
- Arnar ran the console pass from the runbook and handed over both public
  identifiers. Drive Android client (project gen-lang-client-0166122901) and
  Dropbox Scoped/App-folder app key are now in .env, mirrored to app/dev.env.
  Gating is per-connector, so both connectors wake in the same build.
- His Dropbox settings check out from the screenshot: App folder "MyReciBook",
  redirect URI byte-exact, public clients ALLOW (PKCE needs that).
- He asked whether the SHA-1 I printed meant something was wrong — it did not;
  it was a cross-check against his debug keystore, and it matches.
- His downloaded client JSON landed in conductor/, which checkpoint commits
  wholesale — moved to repo root and gitignored (technical rule 10).
- Status: storage is wired but UNPROVEN — nothing has connected on the phone
  yet. Next: the runbook's Part C smoke test on the S21, then his hands-on
  pass and the Play-fee verdict.

## 2026-08-06 (Code, cont.) — Arnar's first hands-on: 7 findings → the app got honest
- Arnar poked the creds-live build and found 7 issues; all but one landed in
  code the same session: status-bar icons stranded after the image viewer ·
  folder screens ignoring his theme · grocery rows now swipe-delete with Undo
  + Clear all behind the 6f confirm · Quick/Sweet chips hidden (Favorites
  only) · Meal plan hidden behind a flag (NOT cut — the bet's hook keeps it).
- Two founder decisions made as partners, against my first defense of the
  mockups: the 5c DRAWER IS REMOVED (after hiding its dead rows it only
  duplicated the bar/Settings) and change-folder goes STRAIGHT to the system
  picker. Cutting the detour exposed a real latent bug: the app subtree now
  remounts keyed by folder, on purpose instead of by accident.
- Detail screen: collapsing hero — the cover scrolls away, reading wins.
- His cover-image wedge (own photo / pick from screenshots) → turn-7 frame;
  AI-generated covers parked. 315 tests green. Latest APK BUILT, NOT
  installed — the S21 was unplugged; he's back with the phone after a workout.
