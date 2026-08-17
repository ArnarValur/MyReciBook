# Relay — MyReciBook
*One entry per session, newest last, ≤10 lines, plain language.
Past 12 entries: trim to newest 8, archive to conductor/pulse-archive/relay-pre-{date}.md.*

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

## 2026-08-09 (Hermes) — review closed: 18 findings fixed · F5 fence · D2 proxy built · fresh build ON the phone
- Ran the correctness lens yesterday's limit killed (7 finders + my verify
  pass): 18 confirmed findings, all fixed same-day. One write discipline now
  (atomic_file.dart) — settings.json was one truncated write from silently
  losing your folder grant.
- F5: sync never overwrites a file edited elsewhere — skips it and the status
  line says "N changed elsewhere". D2 proxy exists in proxy/ (key
  server-side, capped); deploying it is your gcloud call, $0 tier.
- You plugged the S21 in mid-session: fresh upload-key build installed,
  launched clean. The one-time signature flip wiped app-private state —
  re-pick the folder; the recipes in the folder are safe.
- For you: docs/workday-2026-08-09.md (4 decisions). 337+10 tests green.
  Commits d61bf83 + eb2b6a5. Next: your hands-on + storage smoke → verdict → fee.

## 2026-08-09 (Hermes, cont.) — hands-on round 2: camera + Dropbox PROVEN; Drive = one console line away
- Your round 2 on the upload-key build: photographing a recipe extracts
  ("boom works" — first camera proof), screenshots still work, and DROPBOX
  connected and synced on the phone — that half of the storage smoke PASSED.
- Drive's auth error is not GCP being broken: this morning's signing flip
  changed the app's SHA-1 fingerprint, and the Drive Android client only
  trusts the old debug one. Fix (2 min): GCP console → Credentials → ADD an
  Android OAuth client, same package, SHA-1
  B0:E5:3A:23:85:47:3C:24:F6:8D:B5:2F:A4:4A:FD:DA:67:06:58:28 — keep the
  debug client too. Then retry Drive connect; no rebuild needed.
- Graduated as tech rule 9 — the same errand returns at first Play upload
  (Play App Signing = a third cert). Next: SHA-1 in console → Drive smoke →
  your verdict → fee.

## 2026-08-09 (Hermes, evening) — Drive 400 cracked: Google demands the reversed-client-id redirect
- Your new OAuth client + ticked custom-URI box weren't enough: Google's
  policy rejects package-name redirect schemes outright (the 400's own
  request details showed it). Installed apps must redirect to the REVERSED
  client id — com.googleusercontent.apps.<id>:/oauth2redirect.
- Fixed in code, not console: oauth.dart derives the scheme from whatever
  client id the build carries, AuthBridge routes any
  com.googleusercontent.apps.* redirect, the manifest lists one entry per
  client. New client id mirrored into .env/dev.env (gitignored).
- Rebuilt, 338 tests green, installed on the S21 — your Drive retry is the
  open question this checkpoint can't answer. Graduated as tech rule 10;
  the Play App Signing cert will need the same pair of errands (rules 9+10).
- Next: retry Drive → save → files in Drive → kill/reopen = smoke PASSED.

## 2026-08-10 (Hermes) — your logo is the app · screenshots demoted as covers · doc tidy
- Your logo pack landed everywhere it belongs: launcher icon (the Flutter
  default is gone, adaptive + themed variants included), the cookbook header,
  and the Cookbook tab. The app DRAWS the mark from your SVG's paths, so it
  tints with the theme and never pixelates — the svg files stay the authority.
- Covers: you said the screenshots came out ugly, so they are no longer
  promoted to covers at all. A recipe with no cover gets its own drawn tile
  (brand gradient fixed by title + logo watermark), and the hero now carries
  an 'add cover' pill → photo · gallery · a screenshot · remove. Your picture
  is copied into YOUR folder, so it syncs and survives a reinstall.
- Honest gap: 338 tests green, but NONE of them touch the cover flow. That
  path is unproven until we write them. You also told me twice tonight to
  stop test-looping cosmetic work and to deploy to the phone myself.
- My mistake, worth remembering: the first APK I pushed had placeholder OAuth
  keys — I built without --dart-define-from-file=dev.env, which is what the
  "awaiting keys in this build" caption was reporting. Now tech rule 11.
- Docs: five dated session files → docs/archive/. The feasibility report
  stays at root — it is warm reference, not stale.
- Next: your Drive retry is still the one open proof; then cover-flow tests.

## 2026-08-15 (remote, queue-page branch) — queue tab retired: slot 2 sells the app
- Your call from the festival drive: the queue tab is dead weight — that slot
  should let people buy, rate and share instead. Built tonight, on branch
  claude/queue-page-app-promotion-0x9sw8 (NOT yet folded to main).
- Slot 2 = Unlock tab: the 3g "Pay once. Cook forever." pitch promoted from
  the debug gallery (one shared PaywallPitch widget — tab and future paywall
  route can't drift). CTA is honest: disabled + "billing connects when
  MyReciBook reaches the store". Flags: kUnlockTabEnabled (flip back = queue
  tab returns), kSpreadWordEnabled (rate/share rows wait for a live listing).
- The queue itself lives on: batch imports still push the queue screen, and a
  Cookbook strip ("Rescuing N · M need your eyes") + Cookbook-tab badge are
  the way back. Strip gone without residue when everything saves.
- GIFTING CUT: Google Play has no user-to-user gifting for apps or IAPs.
  Honest substitute at launch: Play promo codes (you mint up to 500/quarter
  in the Console) — a marketing tool for you, not an in-app button.
- 341 tests green (3 new on the Unlock tab guard the cap-in-writing line and
  the honest CTA). grocery_flow flaked under this container's load at high
  test concurrency — clean tree flakes identically; not this change.
- Second ask same session (from the road): grid ⇄ list toggle at the far end
  of the Cookbook filter bar. Compact rows (title + meta + favorite heart, no
  cover decode), choice persists via AppSettings ('cookbook_view') through
  new CookbookPrefs — the ThemeModel pattern verbatim. 344 tests green.
- Next: your Drive retry stays the queue head; Play fee after the weekend →
  billing 3g wires the real purchase into the seam this session left.

## 2026-08-17 — Drive smoke PASSED; covers' file half tested; Play profile underway
- Phone on the cable at last: fresh dev.env build → S21. One agreed data
  wipe on install — the old APK came from another machine's debug keystore
  (now tech rule 15); after that, same-keystore reinstalls kept your data.
- Your pass on the device: Unlock tab + grid ⇄ list toggle look right, and
  Google Drive connects and syncs — the smoke heading the queue since
  09 Aug is DONE. Both connectors are now proven on your phone.
- Your call, shipped same hour: "Why not a subscription?" is a static card
  now — a one-paragraph collapse had no reason to fold.
- Covers: the file side is tested (photo copied in, jpg↔png swap cleans up,
  remove takes the bytes, delete takes the cover, promote = ref, edit keeps
  it — 6 tests). The tap-choreography tests hung on my bug (real IO outside
  runAsync, tech rule 14) and you dropped them: file deleted, gap accepted.
- Play: you're building the developer profile, expecting it ~tomorrow →
  fee → Console → billing 3g into the seam. That's the next engine work.
