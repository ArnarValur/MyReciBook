# Relay — MyReciBook
*One entry per session, 6 lines max, newest first.*

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

## 2026-08-28 — the rough corners named and sanded, 0.16.0 → 0.17.5+29

- Shipped: cookbook as a folded tag shelf (untagged flat, sections alphabetical,
  chips = All + Favorites), full-page tag editor wired into the recipe picker,
  diary meals in the shelf card, inset-aware bottom-bar clearance, scan skips
  tags.json, Trends drops all-zero rows, label micros forced to grams.
- Broke: an agent's Center in bottomNavigationBar shipped a BLANK tag editor
  (0.17.1→.4); Arnar caught it on device. Widget test now pins the body.
- Arnar: colour-by-tag everywhere, heart red everywhere, no icon search,
  no "Untagged" heading, ~8dp air over the nav pill.
- UNFINISHED: his oats file still carries 30.4 g folate — he re-reads the label
  on the product page. Full suite still unrun since 2026-08-21.

## 2026-08-27 — pantry scan doors, label reading, and four design agents welded

- Scan bar was wrapped in IgnorePointer: a miss was a dead end, a hit could not
  be checked. Both now act — 'Add it' creates with the barcode on the file,
  'Check' opens what was just saved. 0.15.0+18.
- Label reading off the pack, up to three photos, one AI call. Needed NO server
  change: the proxy forwards bodies verbatim. Prompt asks the model to omit
  what it cannot read; label_read.dart drops impossible values rather than
  clamping them. First prompt refused non-food — wrong question, since coffee
  and spices have no nutrition table either; it now asks only whether there is
  a label to read.
- Four agents built designs 1b, 1c, 2a/2b and 3a/3b in parallel worktrees and
  were welded to 0.16.0+21. Both shelves came back on the shared contract, so
  welding was choosing one. Agents branched two commits stale; only the
  pantry_tab import block conflicted.
- Agent catches worth keeping: SIZE was not a new field (Product.quantity held
  it), and a barcode-less food's rename is a file move — a data-loss hazard the
  moment saving went automatic.
- Arnar: Quick add parked not deleted (kQuickAddEnabled) — he could not tell
  from the label what it did; 'Log it without numbers' added to the linking
  sheet so an unlinked meal is still recordable, with absent values not zeros.
- UNFINISHED: Arnar sees multiple rough corners in the welded Food surfaces,
  not yet named. Product photos on diary and add-sheet cards still open —
  tension with mockup 1a's provenance avatars written up in the diary plan.

## 2026-08-27 — the folder-pointer backup bug, a welcome flow, and tags

- Shipped 0.14.0+17: settings.json no longer carries tree_uri — it rides
  Android backup, so a restored install met "your recipes folder moved" as its
  FIRST screen. Split into device.json, excluded from backup and D2D.
- Welcome → first-time setup → feature slides, built from Arnar's Claude Design
  mockup. Onboarding is versioned, not a bool: bumping kOnboardingVersion
  replays the slides as a what's-new. Screenshots still pending his crops.
- Tags shipped whole: 78-icon catalog + 117-emoji palette, tags.json beside the
  recipes, Settings → Tags, tag row on the recipe page, chips in the cookbook
  filter, badges on rows and cover cards. Sweet deleted, Quick kept.
- Two things I got wrong and he caught: I built a BrandMark when LogoMark
  already existed (deleted mine), and I shipped two APKs with plain
  `flutter build apk` instead of deploy-s21.sh — no proxy URL, no connector keys.
- The tags plan claimed "nothing writes recipe tags today". Wrong: link import
  maps recipeCategory/recipeCuisine/keywords into tags, up to 8. Arnar found
  them on his own library. Review screen now shows them before save, and an
  undecorated tag can be deleted without adopting it first.
- Arnar: colour in v1, emoji in, delete strips the name from recipe files,
  units onboarding is Metric/Imperial only, and no i18n on this pass — English
  literals, the sweep picks them up.
- UNFINISHED: nothing pending. Next session is his — barcode scanner and pantry.

## 2026-08-22 — tag system and icon catalog planned, nothing built

- Plan only, no code, no version bump. conductor/tracks/tags/plan.md on main.
- The track is small because the parts exist: Recipe.tags is already in the file
  format and unused, kRecipeTagsEnabled is already off waiting for this design,
  _filterRow already draws icon+label chips, and pantry's "+ Category" sheet is
  the tag picker's shape.
- Design: membership rides the recipe file, decoration rides tags.json beside it,
  recipe files win — a tag can lose its outfit, never be lost. Icon + showLabel,
  two fields not three modes, so a blank chip is unrepresentable. Icons keyed by
  string not codepoint: --tree-shake-icons strips a runtime-built IconData and it
  only shows in the release APK.
- Arnar: merge to main, continue on the workstation. Five questions unanswered —
  Quick stays or goes, emoji escape hatch, colour in v1, delete semantics, stacking.
- Merged into main after i18n had landed 4 commits ahead; folded gen_l10n into the
  plan (group names and search terms need keys, user tag names never do).
- UNFINISHED: the five questions. No icon name in the plan is compile-checked —
  no Flutter SDK in the web container, so the catalog needs one analyze pass.

## 2026-08-22 — roundup links: asked, checked, answered

- No code. Arnar asked whether a listicle link ("10 Easy One-Pot Pasta
  Recipes") can yield all ten recipes.
- Checked the live page: it carries NO Recipe JSON-LD, only an ItemList of 10
  blurbs, so today's extractor drops to the AI text path and mashes them into
  one. recipeContentFromHtml returns the first Recipe node and stops.
- Answer is yes, and on the free path: the body names all 10 child URLs and
  each child page carries full Recipe JSON-LD (verified on the lemon-pasta
  child). Detect ItemList, harvest links, fan into the existing BatchModel.
- Written up in conductor/scratchpad.md; full plan at
  ~/.claude/plans/question-if-a-link-glowing-unicorn.md. NOT ordered — he was
  asking about feasibility.
