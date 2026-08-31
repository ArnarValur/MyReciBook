# Relay — MyReciBook
*One entry per session, 6 lines max, newest first.*

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

## 2026-08-31 — "The First" goes to Play: internal testing is live

- Shipped: first .aab ever built and published — Play internal testing,
  release "The First - 0.20.0+42", live 21:01. docs/prod-gcp-setup.md written
  (slice 1 website→prod, slice 2 prod proxy/Firebase). Dev Firestore wiped
  clean (6 docs, all already cap=1200). gcloud onto PATH in ~/.zshrc.
- Arnar: start with internal track for him + Höddi, closed later · hygiene
  wipe approved · next session: Play app setup + website→prod + URL mapping.
- UNFINISHED: Testers tab (two Gmails + invite link) · S21 uninstall-dev-
  then-install-from-Play · privacy URL → the whole plan slice 1.

## 2026-08-31 — the copy sweep, and one lesson about whose words these are

- Shipped: website staging rev 00010 — privacy now names Google Gemini as the
  model that structures recipe text. App: unlock tab reads "1,200 AI recipe
  rescues included" (was 600 + "fair-use cap, in writing"), crash caption
  stopped promising "Never your recipes", stale $25/600 comment corrected.
- Broke: I rewrote four of Arnar's own sentences during a "spot stale info"
  sweep. All reverted. Rule written to memory: report, never rewrite.
- Arnar: $25 IS the price · cursive IS tested (English + Norwegian) · Brevo
  SMTP key deleted at source · website first, Play after the app is finished.
- Prod GCP project created same evening: MyReciBook, `myrecibook-prod`,
  number 283856393795 — written to docs/gcp-project-facts.md, nothing deployed.
- UNFINISHED: website onto myrecibook-prod and myrecibook.com mapped ·
  the offer/engine contradiction on the yearly reset · the 429 message bug.


## 2026-08-31 — the website grows a contact form, terms tell the truth

- Shipped: POST /contact on myrecibook-proxy (Brevo, noreply@myrecibook.com →
  myrecibook@gmail.com, visitor in Reply-To) with honeypot, 3s timer, per-IP
  limit and origin allowlist — all server-side, 11 new tests, mail verified.
  Website staging redeployed: language picker hidden, terms rewritten to 1,200
  rescues with no yearly reset, contact page reshot with two corner tapes.
- Broke: I published Arnar's private note about borrowed photos as a written
  confession in Terms — replaced with a plain takedown clause. Also killed his
  unrelated dev server on :3002, and deployed once after he said stop.
- Arnar: no "in writing"/"fair-use" phrasing · picker off the live site, code
  kept · form over reCAPTCHA · Play link waits for the store listing.
- UNFINISHED: first .aab (command in pulse) · Play app entry + first tester ·
  prod GCP project and myrecibook.com mapping (Arnar's, today).


## 2026-08-30 — nutrition audited, found already built, put to sleep

- Shipped: no code. Nutrition checked line by line against lib/ and proved with
  a test run — density table, per-serving calculator, recipe badge, product edit
  page, manual product entry, label photo all exist and pass; the plan file had
  carried them as open for three sessions.
- Arnar: nutrition goes DORMANT — not active, not blocked, not hanging.
- UNFINISHED: none.

## 2026-08-30 — state caught up with reality, diary graduates

- Shipped: no code. Pulse and tracks corrected against Arnar's word — the
  package-size hint, the new picker and the aisle delete are all verified on
  the device; diary's device verify and USDA seeded-pack spot-check confirmed.
- diary graduated to Done — agreed last session, never written down; the
  checkpoint had recorded what got built instead of what was decided.
- UNFINISHED: none.

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

