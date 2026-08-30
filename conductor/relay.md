# Relay — MyReciBook
*One entry per session, 6 lines max, newest first.*

## 2026-08-30 — the counter tells the truth, the aisle gesture dies

- Shipped 0.20.0+42: quota counter fed by the proxy's real count (cached in
  device.json, honest "—" before first contact); package-size math — a linked
  grocery row reads "750 g Flour · 2 × 500 g"; product picker moved onto the
  shared collapsible shelf, category_chips.dart deleted.
- Arnar: aisle corrections deleted — a hidden long-press nobody would find;
  context.md's bet line drops "remembers category corrections". Dependency
  bump (34 outdated) parked to its own session before the Play release.
- UNFINISHED: package-size hint, new picker and the aisle delete are all
  unseen on the device — next session verifies them.

## 2026-08-30 — housekeeping night: deploy, one graduation, stale items culled

- Shipped: no code. Counter+BYOK build onto the S21 as debug-over-debug with
  dev.env keys — data and folder grant kept; release path stays blocked.
- tags graduated to Done (string sweep item handed to i18n); diary pruned to
  device verify + USDA seeded-pack check — photos item was already shipped.
- Arnar: oats re-read dropped (not operational) · burn down remaining code
  work — package-size math, quota feed — until only i18n stays open.
- UNFINISHED: nutrition package-size math (confirmed unbuilt) — next session.

## 2026-08-30 — the counter gets a face, BYOK goes from parked to code

- Shipped: QuotaCounterCard atop Settings (demo numbers, no proxy feed) with
  cog → own-Gemini-key dialog; BYOK end to end — device.json key, every AI
  call flips to direct Gemini; grid cards 168→172 (3px overflow). No bump.
- Broke: dialog controller disposed mid-close animation — fixed same hour.
- Arnar: no request-gating for BYOK, the unlock is the gate · cog lives on
  the counter card. UNFINISHED: quota feed to the card · his re-rescue on +39.

## 2026-08-30 — the website tries Icelandic and Swedish

- Shipped: is.json + sv.json drafted from en.json, locales + flags wired,
  staging redeployed with both — /is/ and /sv/ live behind the dropdown.
- Broke: lid tabs + footer dropped the /is/ prefix — every layout NuxtLink now
  goes through localePath(). No version bump: website, no APK.
- Arnar: draft Icelandic too formal, he rewrites it himself; Höddi gets the
  Swedish. UNFINISHED: both reviews out · privacy/terms/contact/404 unkeyed.

## 2026-08-30 — extraction v2 in the app, split lines grouped in review

- Shipped 0.19.0+38/+39 to S21: model gets trimmed extract.schema.json (no
  invented ids/dates), bucket confidence folded to floats at the extractor
  seam, line_id through prompt → file → review, split line renders once
  with parsed children and one confirm for the whole line.
- Broke: phone run ate the Filling prose as ingredient raws, 1 step left →
  rule 6: prose sections extract both ways; item spelling normalised (rule 4).
- Arnar: go on both fixes.
- UNFINISHED: his re-rescue on +39; app-side flags, regression fixtures,
  prefix-cache check (docs/handoff-extraction-trim.md remainder).

## ## 2026-08-30 — website i18n foundation, UK flag on the lid

- Shipped: @nuxtjs/i18n 10.6.0 en-only foundation (prefix_except_default, no
  browser detection, strictMessage off for inline markup); frontpage + layout
  fully keyed into website/i18n/locales/en.json; sitemap now per-locale.
- Arnar: switcher visible now — flag-only button (UK flag), labels in the
  dropdown, next to the lamp. Staging redeployed on his go.
- UNFINISHED: privacy/terms/contact/404 still English literals; no language two.

## 2026-08-29 — website polish: one story per theme

- Shipped: 410px mobile pass, all 13 items in website/polish-list.md ☑; rescue
  strip theme-matched (tiramisu by day, beef-broccoli by night, CSS swap).
- Copy: "Made for Android" dupes + cap-reset line cut; "fair-use cap, in
  writing" → "included in the price". Staging redeployed on his go.
- Arnar: $25 flat, no .99 — swept repo-wide incl. kUnlockPrice (placeholder).
- UNFINISHED: remaining copy flags in website/copy-notes.md, his call.

## 2026-08-30 — rescue polish: times that survive their own editor

- Shipped 0.19.0+37: status bar anchored app-wide, Retry confirms before
  spending a rescue, cover photo pickable on the rescue form, times split
  Prep/Cook/extras/Total through schema → file → review → detail → cards →
  PDF → row editor (labeled pills); unit flip converts, cover tap ≠ originals.
- Broke: first pass stopped at display — the editor collapsed imported parts
  to one total and 0.19.0 was stamped unverified; Arnar caught both on device.
- Arnar: verify-then-stamp (minor/patch after his eyes only, deploys ride
  +build) · sew every consumer of a changed field before saying done.
- UNFINISHED: none here — next session is the website (tweak list + copy flags).

## 2026-08-30 — the night shift: suite audited, honest for the first time

- Shipped: no code. Night shift ran as armed — analyze clean; all 72 test files
  combed by four agents against lib, findings in docs/test-comb-2026-08-29.md;
  full suite ONE detached run, 55s: 852 tests, 850 green, 2 red.
- Broke: nothing new — the 2 red are cookbook_view's stale "no covers in list
  view" asserts; lib draws list thumbs since 2026-08-28. Left red, his call.
- Arnar: keep the cadence — analyze between changes, warm touched files, full
  suite at bedtime; slow TDD was cold-compile-per-tic, not the tool.
- UNFINISHED: comb repairs undecided · website tweak list + copy flags his.

## 2026-08-29 — friday night: the website grew up

- Shipped: rescue strip from real screenshots (source → review → filed), hero
  scatters wear the tiramisu page + grandma's cursive card, privacy/terms/
  contact drafts (stamped), 404 card, SEO formal (sitemap, robots, schema.org,
  OG index-card), WebP pipeline, Cloud Run staging script (NOT run), dark mode.
- Arnar: footer is "Knitted and Baked by Merkurial-Studio.com · avj.info", no
  DittoDatto; dark = 23:00 navy, not brown, paper stays paper; share-a-copy
  invite parked for his own session; Play entry must be FREE + one-time IAP.
- Staging LIVE on dev Cloud Run (URL in pulse), noindex-guarded, honest 404s.
- UNFINISHED: Arnar's tweak list + copy flags (website/copy-notes.md) tomorrow;
  night shift armed — "run test nightshift" in a fresh session fires the plan.

## 2026-08-28 — the card box lands in Nuxt

- Shipped: website/ carries the "Website Card Box" design canvas as a real Nuxt
  page — box-lid tabs, hero index card, recipe Nº 002, six tilted feature cards,
  taped-in phone, price card, envelope pocket. Material Symbols now local SVGs
  (canvas fetched Google CDN), responsive folds added, real logo mark from the zip.
- Arnar: canvas copy stays verbatim for now, wording syncs later; full suite +
  test comb happen at bedtime, on his "going to sleep" — written into pulse.
- UNFINISHED: his poke-around notes → joint overview; website has no track.

## 2026-08-28 — meal hours, pantry cold start killed, 0.17.5 → 0.18.3+34

- Shipped: Settings → Meals (rename, reorder, optional start hour per meal —
  windows wrap midnight for night shifts, today's shelf dots the current meal);
  pantry cold start fixed — one batched SAF read instead of 226, boot warm,
  spinner + retry; a quarter "+" beside Scan creates a barcode-less product;
  diary cards wear the photo/cover, provenance icon as a corner badge.
- Broke: nothing new; diary_flow and shell tests still expected the pre-0.17.5
  UPPERCASE meal headers — fixed to the shelf-card shape.
- Arnar: meal hours only, day-rollover hour deferred; index-file cache parked
  (batch read carries 1000+); "Save meal times" label is his edit.
- UNFINISHED: oats folate re-read; full suite unrun since 2026-08-21.
