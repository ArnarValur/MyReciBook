// Theme preference, lifted above MaterialApp so themeMode reacts live
// (D3 pattern: pure op → notify → best-effort persist through AppSettings).
// Inert (no settings — the buildApp test seam's default) it stays
// ThemeMode.system forever: exactly the pre-settings behavior.

import 'package:flutter/material.dart';

import '../data/app_settings.dart';

class ThemeModel extends ChangeNotifier {
  ThemeModel({AppSettings? settings})
      : _settings = settings,
        _mode = parse(settings?.themeMode);

  final AppSettings? _settings;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  /// 'light' / 'dark' → the mode; anything else (null, corrupt) → system.
  static ThemeMode parse(String? v) => switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String name(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  Future<void> setMode(ThemeMode m) async {
    if (m == _mode) return;
    _mode = m;
    notifyListeners();
    try {
      await _settings?.setThemeMode(name(m));
    } catch (_) {} // persistence best-effort — in-memory state already live
  }
}
