# Internationalization — diagnosis & prognosis
*2026-08-20. Facts counted from the tree at 0.8.0+5, not from memory.*

## Diagnosis — where we stand

**Infrastructure: zero.**
- No `flutter_localizations`, no `intl` in pubspec. No `l10n.yaml`, no `lib/l10n/`.
- `Locale(` / `supportedLocales` / `AppLocalizations`: 0 hits in 84 dart files.
- `DateFormat` / `NumberFormat`: 0 hits. Every date and number is hand-formatted.
- 151 `Text('literal')` in lib/ui, ~474 human-readable string literals across
  44 UI files / 22k lines.

**Content: already language-neutral. This is the win.**
- assets/structure_prompt.md line 7: "Keep the source language exactly. Do not
  translate anything." A Norwegian screenshot stays Norwegian, always has.
- Recipes and products are user files. Nothing translates them, nothing should.

**The parts that are not UI strings — this is where the cost hides.**
1. Category tags are English strings used as BOTH the stored value and the
   label (`'Dairy'`, `'Spices'` in domain/product_categories.dart, written
   straight into Product.tags). Translating means splitting stored key from
   display label — and migrating files that already exist on phones.
2. starter_foods.dart: 149 curated English names + synonyms, same problem.
3. Ingredient/unit parsing is English keyword matching (domain/units.dart,
   domain/ingredient_parse.dart — 'cup', 'oz', 'pound', 'fl'). Norwegian
   "2 ss smør" does not parse. Neither does Icelandic "2 msk smjör".
4. data/off_client.dart requests product_name with no `lc=` language param —
   we get whatever language OFF happens to hold for that barcode.
5. Decimal comma vs point, date order: hardcoded to one shape.

## Prognosis — what it takes, in order of pain

**A. UI string extraction — boring, safe, bulky.**
Add flutter_localizations + intl, l10n.yaml, move ~474 literals into ARB files.
Mechanical, machine-assistable, low risk. Nothing breaks if it's half-done.

**B. Split stored key from display label — small, and it gets worse with time.**
Category tags and starter-food names become stable keys; the label is looked up.
Touches saved user files, so it needs a migration. Cheapest today; every week of
shipping adds more phones holding English tags in their data.

**C. Per-language parsing — unbounded, needs a native speaker per language.**
Units, quantity words, ingredient line shapes. This is the part that decides
whether the app feels native or feels translated. One language at a time.

**D. Numbers and dates — half a session once intl is in.**

**Separate and cheap:** the Play listing itself translates independently of the
app. ASO in a second language costs no code.

## Recommendation

Do not do A, C or D before paid v1. They buy nothing a paying English-speaking
user notices, and C is a bottomless pit on ≤10 hrs/week.

Do B when the category code is open anyway. It is the only piece that gets
strictly more expensive the longer we ship — every install writes English tags
into files we would later have to migrate.

Realistic shape of a second language, once v1 earns: Norwegian first (the
market you can test in person), A + B + D as one push, C incrementally.
