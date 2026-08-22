// Interface language, lifted above the shell so MaterialApp.locale reacts live
// and the choice persists (same shape as UnitsModel and ThemeModel: pure op →
// notify → best-effort persist through AppSettings). Inert (no settings — the
// buildApp test seam's default) it stays on follow-the-phone forever: exactly
// the pre-toggle behavior.

import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';

import '../data/app_settings.dart';
import '../domain/app_language.dart';

/// ValueListenable so BootGate's own MaterialApp (which lives OUTSIDE the
/// provider tree) can follow the choice too — same reason ThemeModel is one,
/// and the same bug if it isn't: an English gate over a Norwegian app.
class LanguageModel extends ChangeNotifier implements ValueListenable<Locale?> {
  LanguageModel({AppSettings? settings})
      : _settings = settings,
        _language = parseAppLanguage(settings?.language);

  final AppSettings? _settings;
  AppLanguage _language;

  AppLanguage get language => _language;

  /// null hands locale resolution back to the platform — MaterialApp then
  /// matches the phone's language against supportedLocales itself.
  Locale? get locale => appLanguageLocale(_language);

  @override
  Locale? get value => locale;

  Future<void> setLanguage(AppLanguage l) async {
    if (l == _language) return;
    _language = l;
    notifyListeners();
    try {
      await _settings?.setLanguage(appLanguageName(l));
    } catch (_) {} // persistence best-effort — in-memory state already live
  }
}
