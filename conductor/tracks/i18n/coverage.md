# i18n coverage — what a language has to cover to be COMPLETE

*Counted 2026-08-22 by script over lib/. Raw literal counts are UPPER BOUNDS:
they include strings that turn out not to be user-facing. Every bucket below
that says "needs a classification pass" has not been sorted by hand yet.*

Working order (Arnar, 2026-08-22): one language at a time, Icelandic first.
Icelandic is the stress test — four cases, three genders, definite forms. A
string shape that survives it survives the other nine. Gemini then fills the
remaining languages one at a time against the finished English + Icelandic
pair.

## "Finished" means the app speaks it, not that the .arb matches
Arnar, 2026-08-22: **never show the language selection until a language is
actually finished.** A file that matches app_en.arb only proves it kept up
with the strings extracted so far — and most of the app is still hardcoded
English. Íslenska matching 31 messages would have bought an Icelandic
Settings tab in front of an English app.

- `kOfferedLanguages` (lib/domain/app_language.dart) lists languages the app
  genuinely speaks. Today: English only.
- `kLanguageChoiceExists` is derived from it. One language is not a choice, so
  the Settings row and the whole picker are hidden until a second one lands.
  There is no separate feature flag to forget — adding a language to the list
  is the only switch.
- `kOfferedLocales` restricts MaterialApp.supportedLocales the same way, so a
  phone already set to Icelandic is not dropped into a half-translated app
  without ever choosing.
- `test/l10n/arb_parity_test.dart` FAILS the build if an offered language is
  missing a message. The parked files may lag; the test reports how far behind
  each is, and fails them only for inventing keys that are not in app_en.arb.
- `test/ui/language_test.dart` exercises the picker directly, so the code
  keeps working while it waits offstage, and asserts the Settings row tracks
  `kLanguageChoiceExists` rather than any hardcoded expectation.
- Right now: ten .arb files parked. Íslenska covers the Settings tab, the
  other nine hold 31 messages each.

## The surface, bucket by bucket

### A — screen text (lib/ui, dev-only postalpha excluded)
**629 literals, upper bound.** The real chrome. Done: settings_tab.
Heaviest remaining, in the order to take them:

| count | file |
|---|---|
| 56 | lib/ui/pantry/pantry_tab.dart |
| 51 | lib/ui/recipe_detail_screen.dart |
| 49 | lib/ui/import_review_screen.dart |
| 42 | lib/ui/diary/diary_tab.dart |
| 36 | lib/ui/pantry/manual_product_screen.dart |
| 31 | lib/ui/manual_entry_screen.dart |
| 30 | lib/ui/batch_queue_screen.dart |
| 30 | lib/ui/diary/add_food_sheet.dart |
| 29 | lib/ui/grocery_tab.dart |
| 29 | lib/ui/storage_screen.dart |
| 26 | lib/ui/storage_model.dart |
| 21 | lib/ui/unlock_tab.dart |
| 20 | lib/ui/diary/diary_goal_screen.dart |

…then the tail: folder_gate, recipe_list, log_recipe_sheet, barcode_scan,
editor_fields, import_sheet, log_food_sheet, starter_foods_screen,
cook_mode, grocery_model, glass_nav_bar, batch_model, diary_model,
product_picker_sheet, pantry_model, skin, app_shell, plan_tab, food_tab,
category_chips, product_row.

### B — error and status text in lib/data and lib/domain
**244 + 151 literals, upper bound. NEEDS A CLASSIFICATION PASS.**
Mixed: some of these reach the user (sync failures, OAuth failures, "Open
Food Facts didn't answer"), some never do (HTTP headers, JSON keys, unit
parsing tokens in domain/units.dart, API paths in data/remote_store.dart and
data/drive_docs.dart). Nobody has sorted them. Do that before quoting a
number to anyone.

Known user-facing in here: nutrient_display.dart (the coverage note that
travels onto the PDF), storage_model.dart status lines, saf_store /
saf_pantry_store grant-lost messages, off_client, link_extractor,
gemini_extractor failure copy, validate.dart.

### C — the starter food table (code fix FIRST, not translation)
**913 literals** across starter_foods.dart (639) and product_categories.dart
(262), but only ~480 distinct. `'Veggies'` is written out 73 times, `'Fruit'`
43, `'Spices'` 39, `'1 medium'` 38, `'1 tsp'` 33 — every one of the 149 foods
carries its category and serving size as a free English string.

- Category → a key (`Category.veggies`), one display string per category.
  **~14 words to translate, once.**
- Serving size → structured amount + unit, formatted at render.
- The 149 food NAMES stay English by Arnar's call 2026-08-22 — "Cheddar" is
  Cheddar. Revisit only if a user complains.

Translating this table as it stands would create hundreds of duplicate
messages and freeze the bug into eleven languages.

## Cross-cutting — the parts that are not just moving strings

### Plurals — 21 known sites, all currently faked
`'$n item${n == 1 ? '' : 's'}'` is English-only. English has exactly one
rule: 1 is singular, everything else is plural. Almost nothing else works
that way.

Icelandic puts any number ending in 1 — except 11 — back into the singular:

- 21 staður (singular)
- 11 staðir (plural)
- 22 staðir (plural)

CLDR calls that the `one` category for `is`: `n % 10 == 1 && n % 100 != 11`.
The Dart ternary dies at 21. Polish is worse: three categories, and the
boundaries are not the same ones. gen_l10n does ICU plurals properly, which
means these 21 sites get REWRITTEN, not moved:

sync_engine:42 · batch_queue_screen:59,70 · add_food_sheet:298,330 ·
log_recipe_sheet:87 · grocery_model:43,46,98,189 · grocery_tab:340 ·
pantry_model:126 · pantry_tab:99,304 · recipe_detail_screen:342 ·
recipe_list_screen:220 · storage_model:128,169 · storage_screen:67,231 ·
editor_fields:45

### Interpolation — 353 literals contain `$`
Every one is a sentence glued together in Dart. Each needs to become a WHOLE
message in the .arb with a named placeholder, because word order, gender
agreement and case endings move when the language changes. `'Add to $meal'`
cannot be translated as two halves.

### Dates and numbers
Diary dates, "N days ago" in storage_model, and every nutrition figure.
Decimal comma vs point, and month/weekday names, come from `intl` — already a
dependency, not yet used. Touches the nutrition work, not only strings.

### Sorting
Íslenska (þ, æ, ö), Polish (ą, ć, ł) and the Nordics do not sort in ASCII
order. Any alphabetised list — pantry shelf, product picker — needs a
locale-aware collator or it looks broken to a native.

### Fonts and layout
Bundled Plus Jakarta Sans / Inter must carry þ ð æ ö ą ł. The segmented pills
at 360dp are the tight spots: Finnish `Järjestelmä` is 11 chars where English
has 6. Device pass required, not a test.

## Explicitly out of scope
- lib/ui/postalpha/ — 29 literals, reachable only behind `kDebugMode`. Never
  ships. Do not spend strings on it.
- The Play store listing, screenshots and description. Play holds those
  separately from the app; they are their own translation job on the launch
  track.
- Recipe CONTENT. The user's own recipes stay in whatever language they were
  written or imported in. We translate the app, never the food.

## What a "language pack" is, for the Gemini handoff
One file: `app/lib/l10n/app_<code>.arb`, every key present in app_en.arb, no
key that is not. Plus, when it is complete, one line added to
`kOfferedLanguages` in lib/domain/app_language.dart.

Rules that travel with it:
- Endonyms are never translated. `English`, `Norsk`, `Polski` stay put.
- Match the platform's own settings vocabulary in that language, not the
  dictionary. Android Finnish says `Tallennustila`, not `Tallennus`.
- Say what people say, not what the dictionary says. Icelandic for "paste" is
  `líma` in a dictionary and `peista` in a kitchen (Arnar, 2026-08-22).
- Keep the promise in crashReportsCaption: "Never your recipes."
- Never name the developer.
- Flag anything much longer than the English — several strings live in a
  third of a segmented control.
