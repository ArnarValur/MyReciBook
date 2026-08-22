// The language the interface is drawn in. Same shape as UnitSystem: a small
// enum, a forgiving parser, a stable settings string. Adding a language is one
// enum entry, three switch lines, and lib/l10n/app_<code>.arb — nothing else
// moves, and arb_parity_test fails until the .arb file is complete.
//
// Storage strings must never change once shipped: they sit in the user's
// settings.json, and a rename would silently reset everyone's choice.

import 'dart:ui' show Locale;

/// Ordered as the picker lists them: System first because it is the default
/// and not a language, then alphabetically by endonym so someone hunting for
/// their own language finds it where they expect.
enum AppLanguage {
  /// Follow the phone. The default, and the only entry with no fixed locale.
  system,
  danish,
  german,
  english,
  spanish,
  french,
  icelandic,
  italian,
  norwegianBokmal,
  polish,
  finnish,
  swedish,
}

/// Languages that are DONE — every string the user can reach, translated.
/// Not "the .arb file matches app_en.arb": that only proves a language kept
/// up with the strings extracted so far, and most of the app is still
/// hardcoded English. A language joins this list when the app actually
/// speaks it (Arnar, 2026-08-22).
///
/// Working order: one language at a time, Icelandic first — four cases and
/// three genders, so what survives it survives the rest. Íslenska has an
/// .arb file and is NOT on this list yet; it covers the Settings tab and
/// nothing else.
///
/// Adding a language here is the only switch. The picker appears on its own
/// once there is a real choice, and disappears again if there is not — there
/// is no separate feature flag to forget.
const kOfferedLanguages = [
  AppLanguage.system,
  AppLanguage.english,
];

/// Is there anything to choose between? One language is not a choice, and a
/// Settings row that opens a list of one reads as broken. Until a second
/// language is finished the whole control stays hidden.
bool get kLanguageChoiceExists =>
    kOfferedLanguages.where((l) => l != AppLanguage.system).length > 1;

/// Every language with an .arb file, complete or not.
const kAppLanguages = AppLanguage.values;

/// Locales MaterialApp will resolve the phone's setting against. Restricted
/// to the finished ones for the same reason — a phone already set to
/// Icelandic must not be dropped into a half-translated app without ever
/// having chosen it.
List<Locale> get kOfferedLocales => [
      for (final l in kOfferedLanguages)
        if (appLanguageLocale(l) != null) appLanguageLocale(l)!
    ];

/// A saved settings string → the language. Anything else — null, a corrupt
/// entry, a language removed in a later version — reads as follow-the-phone,
/// never a crash and never a wrong-language surprise.
AppLanguage parseAppLanguage(String? v) => switch (v) {
      'da' => AppLanguage.danish,
      'de' => AppLanguage.german,
      'en' => AppLanguage.english,
      'es' => AppLanguage.spanish,
      'fi' => AppLanguage.finnish,
      'fr' => AppLanguage.french,
      'is' => AppLanguage.icelandic,
      'it' => AppLanguage.italian,
      'nb' => AppLanguage.norwegianBokmal,
      'pl' => AppLanguage.polish,
      'sv' => AppLanguage.swedish,
      _ => AppLanguage.system,
    };

/// The settings-file string. Kept identical to the locale code so the two
/// never drift apart (pinned by a test).
String appLanguageName(AppLanguage l) => switch (l) {
      AppLanguage.danish => 'da',
      AppLanguage.german => 'de',
      AppLanguage.english => 'en',
      AppLanguage.spanish => 'es',
      AppLanguage.finnish => 'fi',
      AppLanguage.french => 'fr',
      AppLanguage.icelandic => 'is',
      AppLanguage.italian => 'it',
      AppLanguage.norwegianBokmal => 'nb',
      AppLanguage.polish => 'pl',
      AppLanguage.swedish => 'sv',
      AppLanguage.system => 'system',
    };

/// The locale to force, or null to let the platform resolve it.
Locale? appLanguageLocale(AppLanguage l) =>
    l == AppLanguage.system ? null : Locale(appLanguageName(l));

/// What the picker prints. Endonyms — a language names itself, so someone who
/// lands in the wrong language can still find their way out. "System" is the
/// exception: it is a word, not a language, so it comes from the .arb files
/// like every other translated string.
String appLanguageEndonym(AppLanguage l) => switch (l) {
      AppLanguage.danish => 'Dansk',
      AppLanguage.german => 'Deutsch',
      AppLanguage.english => 'English',
      AppLanguage.spanish => 'Español',
      AppLanguage.finnish => 'Suomi',
      AppLanguage.french => 'Français',
      AppLanguage.icelandic => 'Íslenska',
      AppLanguage.italian => 'Italiano',
      AppLanguage.norwegianBokmal => 'Norsk',
      AppLanguage.polish => 'Polski',
      AppLanguage.swedish => 'Svenska',
      AppLanguage.system => 'System',
    };
