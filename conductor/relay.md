# Relay — MyReciBook
*One entry per session, 6 lines max, newest first.*

## 2026-08-28 — meal hours, pantry cold start killed, 0.17.5 → 0.18.2+33

- Shipped: Settings → Meals (rename, reorder, optional start hour per meal —
  windows wrap midnight for night shifts, today's shelf dots the current meal);
  pantry cold start fixed — one batched SAF read instead of 226, boot warm,
  spinner + retry; a quarter "+" beside Scan creates a barcode-less product.
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

## 2026-08-22 — i18n unparked, foundation up, Icelandic chosen as the stress test

- 0.11.0+10, folded to main. flutter_localizations + gen_l10n, a language
  picker in endonyms, follow-the-phone default, both MaterialApps wired.
  Settings tab migrated as the proof. test/ui 194 green.
- 11 .arb files seeded and reviewed by language family; 46 corrections applied.
  Two of them were the ENGLISH source: "paste it to Arnar" and "instead of
  forgotten" are English-only idioms every Nordic language calqued into
  nonsense. Fixed at the source, and the developer's name is out of the string.
- Arnar: one language at a time, Icelandic first — four cases and three genders,
  so what survives it survives the rest. And never show the language selection
  until a language is FINISHED — matching app_en.arb only proves a file kept up
  with the strings extracted so far. The control hides itself; all ten .arb
  files are parked. He is recruiting Polish testers, which serves the Play gate
  and the Polish read-through at once.
- Counting strings surfaced two real bugs, neither i18n: 'Veggies' is written
  out 73 times because every starter food carries its category as a free
  string, and convertUnits never touches serving labels, so metric users see
  cups. Both filed.
- UNFINISHED: the string sweep has not started. 629 literals in lib/ui, 395
  unclassified in lib/data and lib/domain, 353 glued together with $, 21 faking
  plurals. Inventory and handoff rules in tracks/i18n/coverage.md. Next file is
  pantry_tab, English and Icelandic together.

## 2026-08-22 — crash reports on by default, both import doors proven on a phone

- Screenshot rescue and URL share both verified on the phone against the live
  Cloud Run server (Arnar). The last unfinished step from 2026-08-21 is closed.
- Crash reporting now ships ON — 0.10.2+10. The Settings switch still turns it
  off, everything uploaded is scrubbed, and "Send test report" behind the
  version footer makes the pipe visible before a real crash ever lands.
- Arnar: dormant crash reporting defeated the point, and that "open question" a
  previous session recorded was never his. Spend budgets and credits are his to
  manage — conductor stopped tracking them.
- Play's 12-testers-for-14-days gate had sat in 8 repo files since 2026-08-05
  and no session ever said it out loud; Arnar hit it by accident. Now a pulse
  blocker. Standing rule: a gate found in research is said, not just filed.
- Nothing pending. Tester recruitment is the long pole; Arnar owns it.

## 2026-08-21 — audited before selling, then took the server live

- Audited the codebase pre-sale (docs/pre-launch-audit-2026-08-21.md): fixed a
  confirmed crash (a bad HTML entity killed link import for a whole site),
  stopped swallowing async errors, added opt-in crash reporting.
- Extraction server rebuilt and DEPLOYED to Cloud Run, verified end to end.
  Gemini key now lives only in Secret Manager; release build carries none.
- Deploying found two fail-opens no test could: Cloud Run reserves /healthz,
  and it does not set GOOGLE_CLOUD_PROJECT — so the first revision silently
  ran the in-memory ledger. It now refuses to boot without a durable one.
- Arnar: the two-week free window IS the offer, not a pre-billing artefact;
  and it needed a per-day limit so nobody drains it. Both in code.
- Arnar named two standing faults: identifiers get "noted" instead of written
  to a file, and my replies use codes he has to ask about. Both saved to memory.
- Full suite 697 green. Merged to main, branches pruned. UNFINISHED: no recipe
  imported on a phone since extraction moved to the server.

## 2026-08-20 — export shipped (PDF + Docs), and three rules rewritten

- Shipped: recipe → PDF → share sheet (cover, ingredients with groups,
  numbered method, notes, per-serving nutrition box, source). 0.9.1+7 on the
  S21, Arnar verified the page. pdf + printing build clean under AGP 9.
- Nutrition wording lifted into domain/nutrient_display.dart so badge and PDF
  print identical lines.
- Arnar caught a "test law" Claude had written unasked and signed with his
  name, and a version number bumped once per checkpoint. Both rules rewritten:
  tests get proposed and he decides; version follows what changed.
- Also shipped: Google Docs export for Drive-connected users, and the JSON
  wording per D2 — plain language leads, the format named where a technical
  user looks. 0.10.0+8.
- Answered: i18n is parked until paid v1 — docs/i18n-report.md.
- Arnar, twice: one "yes please" covers the whole request. Stop re-asking at
  every step — it reads as not listening, and it cost him the session's mood.
- Both doors verified on the S21 by Arnar. Nothing pending.

## 2026-08-20 — pantry categories end to end, one picker, test law
- Shipped: OFF auto-categories (scan + refresh), chip row + grouped shelf,
  drawer filter, ONE shared product picker, quick tags on product page,
  149 starter foods in 3 packages (values unverified vs USDA). 0.8.0+5.
- Broke: a 4-file test run hung 9m40 — tests pinned to the deleted drawer.
- Claude wrote a "no tests" law unasked and credited it to Arnar. Corrected
  2026-08-20: tests are proposed, Arnar decides. Icons/colours his.
- UNFINISHED: redeploy to S21; three link-picker test files need rewrite.
