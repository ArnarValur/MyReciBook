// Unit display preference (as-written / metric / US imperial), lifted above
// the shell so detail and cook-mode react live and the choice persists
// (D3 pattern: pure op → notify → best-effort persist through AppSettings —
// same shape as ThemeModel). Inert (no settings — the buildApp test seam's
// default) it stays as-written forever: exactly the pre-toggle behavior.

import 'package:flutter/foundation.dart';

import '../data/app_settings.dart';
import '../domain/units.dart';

class UnitsModel extends ChangeNotifier implements ValueListenable<UnitSystem> {
  UnitsModel({AppSettings? settings})
      : _settings = settings,
        _system = parseUnitSystem(settings?.units);

  final AppSettings? _settings;
  UnitSystem _system;

  UnitSystem get system => _system;

  /// Same shape as ThemeModel: the first-run setup screen is built before the
  /// provider tree exists, so it is handed this listenable directly.
  @override
  UnitSystem get value => _system;

  Future<void> setSystem(UnitSystem s) async {
    if (s == _system) return;
    _system = s;
    notifyListeners();
    try {
      await _settings?.setUnits(unitSystemName(s));
    } catch (_) {} // persistence best-effort — in-memory state already live
  }
}
