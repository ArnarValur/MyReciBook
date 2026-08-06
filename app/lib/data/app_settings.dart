// App config that must survive restarts: the picked SAF tree and the one-shot
// migration flag. One JSON file in app-support storage, read once at load,
// written through on every set. Corrupt/missing file → defaults, never fatal.

import 'dart:convert';
import 'dart:io';

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

  Future<void> setTreeUri(String? uri) => _write('tree_uri', uri);

  Future<void> setMigrationDone(bool done) => _write('migration_done', done);

  Future<void> _write(String key, Object? value) async {
    _data[key] = value;
    await _file.parent.create(recursive: true);
    await _file.writeAsString(jsonEncode(_data));
  }
}
