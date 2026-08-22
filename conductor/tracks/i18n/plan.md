# i18n

**Goal:** the app speaks the user's language. Interface strings first; recipe
content stays in whatever language the user wrote or imported it in.

**Serves:** the Play tester gate — 12 people installed for 14 straight days —
is the long pole and nobody is recruited yet (Arnar, 2026-08-22: "might as
well use the time and polish and shine"). Every language also widens the pool
of people who could BE those testers.

**Unparked 2026-08-22.** Pulse had it filed under "i18n until paid v1".
Arnar moved it to a track.

## Languages — Arnar's list, 2026-08-22
English (source) · Íslenska · Norsk bokmål · Svenska · Suomi · Dansk ·
Deutsch · Français · Español · Italiano · Polski.

One at a time, Icelandic first (Arnar, 2026-08-22): if the strings survive
four cases and three genders they survive everything. Only COMPLETE languages
are offered — `kOfferedLanguages` in domain/app_language.dart, enforced by
arb_parity_test. The other nine files sit at 31 messages and lag on purpose.
Arnar is recruiting Polish testers, which serves the Play tester gate and the
Polish read-through at the same time.

## Decisions
- D1 — the picker lists languages in ENDONYMS, each in its own alphabet.
  Someone who lands in the wrong language by accident can still read their way
  out. "System" is the exception: a word, not a language, so it translates.
- D2 — default is follow-the-phone, not English. MaterialApp.locale stays null
  and the platform resolves it against the supported list.
- D9 — the language selection does not appear until a language is FINISHED
  (Arnar, 2026-08-22). Matching app_en.arb is not finished: it only means the
  file kept up with the strings extracted so far. Íslenska is parked with the
  rest until the app actually speaks it. `kLanguageChoiceExists` derives the
  visibility from `kOfferedLanguages`, so there is no flag to forget.
- D3 — settings strings are the locale codes ('nb', 'is', …) and never change
  once shipped. A rename would silently reset every user's saved choice.
  A test pins the code and the settings string to each other.
- D4 — a missing translation falls back to English rather than rendering
  blank. That is right at runtime and exactly why a gap can ship unnoticed, so
  arb_parity_test fails the build on a missing OR an invented key.
- D6 — when a string translates badly into several languages at once, fix the
  ENGLISH, not the translations. Two source strings were the bug: "paste it to
  Arnar" (person-as-destination is English-only — every Nordic language
  calqued it into nonsense) and "instead of forgotten". Both rewritten
  2026-08-22, and the @description now warns the next translator.
- D7 — agent translations come out FORMALLY correct and colloquially stiff.
  Arnar's example 2026-08-22: Icelandic for "paste" is `líma`, which is right
  in a dictionary and which nobody says — people say `peista`. An agent will
  never reach for the loanword. This is what the human pass is for, and it is
  a reason to prefer plain verbs in the English source that do not have a
  dictionary-vs-street split.
- D8 — no personal names in strings. `send it to Arnar` meant nothing to a
  stranger, and every language had to guess at "þróunar gaurinn". Now
  "the developer" (Arnar, 2026-08-22). Still writes a cheque the app cannot
  cash: it says send, and gives no address. Blocked on the feedback channel.
- D5 — translations are produced and reviewed by agents, one language list at
  a time (Arnar's method, 2026-08-22). Native passes come from people: Arnar
  has Polish friends who can read Polski, and users report what reads wrong
  (2026-08-22). That makes the parked "user feedback channel" load-bearing for
  this track — a wrong string with nowhere to report it stays wrong.

## Built (branch i18n, 0.11.0+10, not folded to main)
- [x] flutter_localizations + intl, l10n.yaml, generate: true. Generated code
      is gitignored — `flutter pub get` rebuilds it, verified from a clean dir
- [x] domain/app_language.dart — enum, parser, settings string, endonym
- [x] ui/language_model.dart — same shape as UnitsModel/ThemeModel; persists
      through AppSettings.setLanguage; ValueListenable so the boot gate's own
      MaterialApp follows it too (else an English gate over a Norwegian app)
- [x] Both MaterialApps carry the delegates and supportedLocales
- [x] ui/language_screen.dart — pushed picker, the Storage row shape. Eleven
      languages plus System never fit the segmented pill Theme and Units use
- [x] Settings tab fully migrated as the proof: `context.l10n.foo`
- [x] 11 .arb files, 31 messages each. Reviewed by language family and
      corrected: 6 Icelandic, 4 Norwegian, 2 Danish, 5 Swedish, 5 Finnish,
      4 German, 5 French, 5 Spanish, 3 Italian, 7 Polish
- [x] Only COMPLETE languages are offered — kOfferedLanguages in
      domain/app_language.dart drives the picker AND supportedLocales, so
      following the phone cannot land in a half-translated language either
- [x] test/l10n/arb_parity_test.dart — fails the build if an OFFERED language
      is missing a message; reports the backlog for the parked ones without
      failing them. test/ui/language_test.dart covers the picker and
      persistence. 50 green

## Coverage
The full inventory — every bucket a language has to cover, the 21 plural
sites, the 353 interpolated strings, and the Gemini handoff rules — lives in
tracks/i18n/coverage.md. Counted 2026-08-22.

## Open
- [ ] Extract the rest. Counted 2026-08-22, and it splits in two:
      - lib/ui chrome: 689 occurrences, 609 distinct. Only 64 repeat, worth 80
        saved — UI strings are genuinely different from each other, there is
        no big dedup win here. Heaviest first: recipe_detail, import_review,
        grocery_tab, pantry_tab, storage_screen, manual_entry, diary sheets.
        postalpha/preview_screens is dead weight — check before spending
        strings on it.
      - lib/data + lib/domain: 399 occurrences, mostly error and status text.
- [ ] BEFORE translating anything: fix starter_foods.dart and
      product_categories.dart in CODE, not in .arb. 901 string occurrences but
      only 480 distinct — 'Veggies' appears 73 times, 'Fruit' 43, 'Spices' 39,
      '1 medium' 38, '1 tsp' 33. Each of the 149 starter foods carries its
      category and its serving size as a free English string. Category should
      be a key with one display string per category (~14), serving size a
      structured amount+unit formatted at render. Translating the table as it
      stands would create hundreds of duplicate messages and freeze the bug
      into eleven languages.
- [ ] Share only genuinely context-free words (Cancel, Close, Done, Retry).
      Two strings being identical in English is NOT a reason to share a key —
      "Add" as a button and "Add" as a heading inflect differently in most of
      these languages, and a shared key cannot be fixed for one without
      breaking the other.
- [ ] Translate each new batch the same way: one agent per language list,
      reviewed, then the next
- [ ] Plurals and dates. gen_l10n does ICU plurals; several strings today fake
      it with `${n == 1 ? '' : 's'}`, which does not survive translation.
      Nordic and Polish need real plural categories — Polish has three
- [ ] Number and unit formatting per locale (decimal comma vs point) —
      touches the nutrition and units work, not just strings
- [ ] android:localeConfig in the manifest, so Android 13+ shows MyReciBook in
      the system per-app language list
- [ ] Play listing: the store description and screenshots are their own
      translation job, and Play holds them separately from the app
- [ ] Device pass on a phone — the picker, and the segmented pills at 360dp:
      Finnish "Järjestelmä" (11 chars where English has 6) and the German and
      Icelandic unit labels are the tight ones. Also check Icelandic and
      Polish diacritics render in the bundled fonts
