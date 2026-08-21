// App config that must survive restarts: the picked SAF tree and the one-shot
// migration flag. One JSON file in app-support storage, read once at load,
// written through on every set. Corrupt/missing file → defaults, never fatal.

import 'dart:convert';
import 'dart:io';

import 'atomic_file.dart';
import 'crash_reporter.dart' show kCrashReportingDefaultOn;

class AppSettings {
  AppSettings._(this._file, this._data);

  final File _file;
  final Map<String, dynamic> _data;

  static Future<AppSettings> load(File file) async {
    Map<String, dynamic> data = {};
    try {
      if (await file.exists()) {
        data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      }
    } catch (_) {} // corrupt settings: start from defaults
    return AppSettings._(file, data);
  }

  /// Tree URI of the user-picked recipes folder; null until first pick.
  String? get treeUri => _data['tree_uri'] as String?;

  /// One-shot local→SAF migration already ran.
  bool get migrationDone => _data['migration_done'] as bool? ?? false;

  /// Active storage connector ('drive' / 'dropbox'); null = this phone only.
  /// Unknown values read as null — a corrupt entry is a disconnect, not a crash.
  String? get activeConnector {
    final v = _data['active_connector'];
    return v == 'drive' || v == 'dropbox' ? v as String : null;
  }

  /// Theme preference ('system' / 'light' / 'dark'); default system.
  /// Unknown values read as 'system' — a corrupt entry is a default, not a crash.
  String get themeMode {
    final v = _data['theme_mode'];
    return v == 'light' || v == 'dark' ? v as String : 'system';
  }

  /// Cookbook layout ('grid' / 'list'); default grid (the designed 3d form).
  /// Unknown values read as 'grid' — a corrupt entry is a default, not a crash.
  String get cookbookView {
    final v = _data['cookbook_view'];
    return v == 'list' ? 'list' : 'grid';
  }

  /// Send crash reports off the device. Absent — nobody has touched the
  /// toggle — falls back to [kCrashReportingDefaultOn], so flipping that one
  /// constant moves the default for fresh installs without overriding anyone
  /// who already chose. The local crash log runs regardless of this.
  bool get crashReportingEnabled =>
      _data['crash_reporting'] as bool? ?? kCrashReportingDefaultOn;

  /// Unit display ('as_written' / 'metric' / 'imperial'); default as-written.
  /// Unknown values read as 'as_written' — a corrupt entry is a default, not a crash.
  String get units {
    final v = _data['units'];
    return v == 'metric' || v == 'imperial' ? v as String : 'as_written';
  }

  /// Daily calorie target for the diary. Null = no goal set, and the diary
  /// says "no goal yet" instead of measuring you against a number nobody
  /// chose. Zero or negative reads as unset.
  double? get calorieGoal {
    final v = _data['calorie_goal'];
    if (v is! num || v <= 0) return null;
    return v.toDouble();
  }

  /// Daily macro targets in grams, same stance: absent means the diary shows
  /// the number without a bar behind it.
  double? macroGoal(String key) {
    final v = (_data['macro_goals'] as Map?)?[key];
    if (v is! num || v <= 0) return null;
    return v.toDouble();
  }

  /// Meal headings in order. Defaults to the four the diary ships with;
  /// a corrupt or empty list reads as the defaults, never an empty day.
  List<String> get mealNames {
    final v = _data['meal_names'];
    if (v is! List) return const [];
    final names = [
      for (final n in v)
        if (n is String && n.trim().isNotEmpty) n.trim()
    ];
    return names.isEmpty ? const [] : names;
  }

  Future<void> setTreeUri(String? uri) => _write('tree_uri', uri);

  Future<void> setCalorieGoal(double? kcal) =>
      _write('calorie_goal', kcal != null && kcal > 0 ? kcal : null);

  Future<void> setMacroGoal(String key, double? grams) async {
    final goals = Map<String, dynamic>.from(
        (_data['macro_goals'] as Map?)?.cast<String, dynamic>() ?? {});
    if (grams != null && grams > 0) {
      goals[key] = grams;
    } else {
      goals.remove(key);
    }
    await _write('macro_goals', goals.isEmpty ? null : goals);
  }

  Future<void> setMealNames(List<String> names) => _write('meal_names', names);

  Future<void> setUnits(String units) => _write('units', units);

  Future<void> setThemeMode(String mode) => _write('theme_mode', mode);

  Future<void> setCookbookView(String view) => _write('cookbook_view', view);

  Future<void> setActiveConnector(String? provider) =>
      _write('active_connector', provider);

  Future<void> setMigrationDone(bool done) => _write('migration_done', done);

  Future<void> setCrashReportingEnabled(bool on) =>
      _write('crash_reporting', on);

  Future<void> _write(String key, Object? value) async {
    _data[key] = value;
    // Atomic: this file holds tree_uri — a truncated write here would cost
    // the user their folder grant on next boot.
    await writeStringAtomic(_file, jsonEncode(_data));
  }
}
