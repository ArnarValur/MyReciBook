// App config that must survive restarts: the picked SAF tree and the one-shot
// migration flag. One JSON file in app-support storage, read once at load,
// written through on every set. Corrupt/missing file → defaults, never fatal.

import 'dart:convert';
import 'dart:io';

import 'atomic_file.dart';

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

  /// Unit display ('as_written' / 'metric' / 'imperial'); default as-written.
  /// Unknown values read as 'as_written' — a corrupt entry is a default, not a crash.
  String get units {
    final v = _data['units'];
    return v == 'metric' || v == 'imperial' ? v as String : 'as_written';
  }

  Future<void> setTreeUri(String? uri) => _write('tree_uri', uri);

  Future<void> setUnits(String units) => _write('units', units);

  Future<void> setThemeMode(String mode) => _write('theme_mode', mode);

  Future<void> setCookbookView(String view) => _write('cookbook_view', view);

  Future<void> setActiveConnector(String? provider) =>
      _write('active_connector', provider);

  Future<void> setMigrationDone(bool done) => _write('migration_done', done);

  Future<void> _write(String key, Object? value) async {
    _data[key] = value;
    // Atomic: this file holds tree_uri — a truncated write here would cost
    // the user their folder grant on next boot.
    await writeStringAtomic(_file, jsonEncode(_data));
  }
}
