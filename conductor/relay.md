# Relay — MyReciBook
*One entry per session, newest last, ≤10 lines, plain language.
Past 12 entries: trim to newest 8, archive to conductor/pulse-archive/relay-pre-{date}.md.*

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

## 2026-08-17 night — pantry PoC: your kitchen became files in one sitting
- The OFF spike said 15/15, so we built the whole capture loop same night:
  three parallel agents (scan spike · product store · OFF client), wired
  into a Pantry tab on slot 2, all on branch poc/pantry — main untouched.
- You swept 28 real products "beep, beep, beep" in collect mode, added
  photos (camera + gallery), and long-press-linked ingredients to YOUR
  products — Mellommelk answering "250ml Milk". Search + thumbnails in
  the picker, per-100g macros on every product page.
- Discovery that changes T5: the qty/unit/item split has been in the
  schema since D1 and the extractor already fills it. Phase 0 was free.
- Honest gaps: pantry doesn't sync yet (needs a pantry/ case), so it
  doesn't follow your folder — first job after you call the fold.
- Your brainstorms banked in the T5 plan: remembered links, grocery rows
  as products (staples hide qty → "you have it" → package math), and the
  named trap we will not build: inventory tracking.
- Next: your Play profile → billing 3g stays the engine seam; fold call
  on poc/pantry when you're ready.

## 2026-08-17 late-night — folded, then the follow-on left the runway
- You called the fold: the whole pantry PoC is on main (fast-forward,
  95408ce), poc/pantry deleted. Your kitchen feature is now the app.
- You picked the next two from the menu: the pantry/ sync case (products
  + photos finally follow YOUR folder, with a migration for your 28) and
  grocery tiers 1+2 ("Sugar", not "2 cups sugar" · "in your pantry" hint).
- Both are running as parallel agents on branch poc/pantry-follow at this
  checkpoint — nothing merged yet. The sync agent's brief carries the
  delete-safety rules in writing; I review its work before it touches
  anything, because a sync-layout mistake can wipe remote files.
- Next session opens on: their two reports → hard review of sync → wire,
  test, S21. Then remembered links.

## 2026-08-17 late-night — the pantry moved into your folder, for real
- Both agents landed and are merged on poc/pantry-follow (not folded —
  your call). Your 28 products and 3 photos now live in
  /sdcard/MyReciFolder/pantry, moved by a boot migration I watched run on
  your phone; the old app-private copy is gone. Pantry travels on Drive
  and Dropbox like recipes now — the "files you own" gap is closed.
- Grocery got your two tiers: staples say "Sugar", not "2 cups sugar";
  rows built from a linked ingredient show a quiet "in your pantry" hint
  and never remove themselves; two rows meaning the same product merge
  without asking.
- I reviewed the sync work myself before merging (it can delete remote
  files) — the layout filter stayed strict and the migration verifies
  every copy before deleting anything.
- Correction worth knowing: two failing shell tests were blamed on the
  sync agent; they were mine, from renaming nav slot 2 to Pantry. Fixed,
  and the lesson is now a rule.
- FULL SUITE 454/454, run serially — first complete run in a while.
- Next: fold poc/pantry-follow when you say so; then remembered links.

## 2026-08-18 — short session: pulse cleaned, nothing built
- The pulse was out of date: it claimed the pantry work was still waiting on
  a side branch for your fold call. It was already on main. Corrected.
- You said the gates are noise. They're out of the pulse and out of the boot
  report — the stop-rules stay written in context.md, I just won't recite
  them at you. Graduated as behavioral rule 22.
- You said no to N7 (remembered links) for now. Recorded, not re-queued.
- I raised a keystore backup and oversold it as urgent. You were right that
  it isn't — nothing is on Play yet, so a lost key costs nothing today.
  Dropped; it comes back at the first upload.
- I explained things badly this whole session and you told me so three
  times. No code changed, no tests run. Nothing is broken.
- Next: your call — Play profile / billing, landing page, or unit table.

## 2026-08-18 (later) — pulse stripped of everything you own
- You told me three times to stop echoing your own to-dos back at you. Fixed
  at the source, not in memory: they're purged from pulse, from tracks.md,
  and from anything the boot report reads.
- Blockers is empty. There is nothing on my side waiting.
- Next queue is EMPTY on purpose. I stopped filling it myself — from now on
  I ask you what goes in it and write down your answer, nothing else.
- Graduated as behavioral rules 24 and 25. Strike either if I read you wrong.
- No code touched, no tests run.
- Next: tell me what goes in the queue.

## 2026-08-18 (evening) — boot found your wipe; citations cleared
- Boot flagged one thing git had that pulse didn't: your commit 158b0ec
  emptied behavioral.md (103 lines gone) and cut graduation out of
  /checkpoint. Deliberate, your hand — I did not restore it.
- I over-explained that finding. You told me to clear it and move on.
- Cleared: pulse no longer cites behavioral rules that don't exist.
  technical.md is untouched and still live.
- Pulse now says plainly that the behavioral file is empty on purpose, so
  the next boot doesn't rediscover it and hand you the same paragraph.
- No code touched, no tests run. Nothing built this session.
- Next: your pick — unit table → nutrition badge (T5), or the landing page.
