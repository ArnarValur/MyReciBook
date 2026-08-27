// App config that must survive restarts. TWO JSON files in app-support, split
// by one rule: does this value make sense on a DIFFERENT phone?
//
//   settings.json — portable. Theme, language, units, goals. Rides Android's
//     cloud backup and phone-to-phone transfer, and should.
//   device.json   — this install only. The SAF tree URI and the onboarding
//     version. EXCLUDED from backup in res/xml/*_rules.xml.
//
// Why the split (2026-08-27): tree_uri used to live in settings.json, so a
// restored backup handed a fresh install a folder path it had no permission
// for — and the boot gate correctly, uselessly, said "your recipes folder
// moved or access was lost" as the very first screen on a brand-new phone.
// A folder grant cannot travel between devices, so its pointer must not either.
//
// Both files: read once at load, written through on every set.
// Corrupt/missing file → defaults, never fatal.

import 'dart:convert';
import 'dart:io';

import 'atomic_file.dart';
import 'crash_reporter.dart' show kCrashReportingDefaultOn;

class AppSettings {
  AppSettings._(this._file, this._data, this._deviceFile, this._device);

  final File _file;
  final Map<String, dynamic> _data;
  final File _deviceFile;
  final Map<String, dynamic> _device;

  /// Keys that live in device.json instead of settings.json. Adding one here
  /// is the whole mechanism — [_write] and the getters route on this set.
  static const _deviceKeys = {'tree_uri', 'onboarding_seen'};

  /// [deviceFile] defaults to `device.json` beside [file]. Pass it explicitly
  /// only to point the two somewhere else.
  static Future<AppSettings> load(File file, {File? deviceFile}) async {
    final dev = deviceFile ?? File('${file.parent.path}/device.json');
    Map<String, dynamic> data = {};
    Map<String, dynamic> device = {};
    try {
      if (await file.exists()) {
        data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      }
    } catch (_) {} // corrupt settings: start from defaults
    try {
      if (await dev.exists()) {
        device = jsonDecode(await dev.readAsString()) as Map<String, dynamic>;
      }
    } catch (_) {} // same stance for the device file
    final s = AppSettings._(file, data, dev, device);
    await s._adoptLegacyDeviceKeys();
    return s;
  }

  /// One-shot carry-over for installs written before the split: move any
  /// device key still sitting in settings.json into device.json and clear it
  /// from the portable file, so the next backup can no longer carry it.
  /// Silent on failure — a settings file we cannot write is not fatal here.
  Future<void> _adoptLegacyDeviceKeys() async {
    var moved = false;
    for (final key in _deviceKeys) {
      if (_device.containsKey(key) || !_data.containsKey(key)) continue;
      _device[key] = _data[key];
      _data.remove(key);
      moved = true;
    }
    if (!moved) return;
    try {
      await writeStringAtomic(_deviceFile, jsonEncode(_device));
      await writeStringAtomic(_file, jsonEncode(_data));
    } catch (_) {}
  }

  /// Tree URI of the user-picked recipes folder; null until first pick.
  /// Lives in device.json — see the file header.
  String? get treeUri => _device['tree_uri'] as String?;

  /// Onboarding version this install has completed; 0 = never. Compared
  /// against [kOnboardingVersion]: lower means the welcome flow runs again,
  /// so bumping that constant after a notable release replays the slides for
  /// everyone as a short "what shipped" intro (Arnar 2026-08-27).
  /// Lives in device.json, so a fresh install always replays.
  int get onboardingSeen {
    final v = _device['onboarding_seen'];
    return v is int && v > 0 ? v : 0;
  }

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

  /// Interface language ('en' / 'nb' / 'system'); default system, i.e. follow
  /// the phone. Unknown values read as 'system' — a corrupt entry, or a
  /// language dropped in a later version, is a default, not a crash.
  String get language => _data['language'] as String? ?? 'system';

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

  Future<void> setOnboardingSeen(int version) =>
      _write('onboarding_seen', version);

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

  Future<void> setLanguage(String language) => _write('language', language);

  Future<void> setThemeMode(String mode) => _write('theme_mode', mode);

  Future<void> setCookbookView(String view) => _write('cookbook_view', view);

  Future<void> setActiveConnector(String? provider) =>
      _write('active_connector', provider);

  Future<void> setMigrationDone(bool done) => _write('migration_done', done);

  Future<void> setCrashReportingEnabled(bool on) =>
      _write('crash_reporting', on);

  Future<void> _write(String key, Object? value) async {
    final device = _deviceKeys.contains(key);
    final map = device ? _device : _data;
    if (value == null) {
      map.remove(key);
    } else {
      map[key] = value;
    }
    // Atomic: device.json holds tree_uri — a truncated write there would cost
    // the user their folder grant on next boot.
    await writeStringAtomic(
        device ? _deviceFile : _file, jsonEncode(map));
  }
}
