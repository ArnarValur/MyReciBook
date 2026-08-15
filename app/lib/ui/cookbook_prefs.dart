// Cookbook layout preference (grid with covers vs compact list), lifted
// above the shell so it survives tab switches and persists across restarts
// (D3 pattern: pure op → notify → best-effort persist through AppSettings —
// same shape as ThemeModel). Inert (no settings — the buildApp test seam's
// default) it stays grid forever: exactly the pre-toggle behavior.

import 'package:flutter/foundation.dart';

import '../data/app_settings.dart';

enum CookbookView { grid, list }

class CookbookPrefs extends ChangeNotifier {
  CookbookPrefs({AppSettings? settings})
      : _settings = settings,
        _view = parse(settings?.cookbookView);

  final AppSettings? _settings;
  CookbookView _view;

  CookbookView get view => _view;

  /// 'list' → list; anything else (null, corrupt) → grid, the designed 3d
  /// default.
  static CookbookView parse(String? v) =>
      v == 'list' ? CookbookView.list : CookbookView.grid;

  static String name(CookbookView v) =>
      v == CookbookView.list ? 'list' : 'grid';

  Future<void> setView(CookbookView v) async {
    if (v == _view) return;
    _view = v;
    notifyListeners();
    try {
      await _settings?.setCookbookView(name(v));
    } catch (_) {} // persistence best-effort — in-memory state already live
  }
}
