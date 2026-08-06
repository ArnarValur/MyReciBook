// AppSettings: read-once, write-through JSON file; missing/corrupt → defaults.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/app_settings.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recibook_settings_test');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  File file() => File('${tmp.path}/nested/settings.json');

  test('missing file → defaults', () async {
    final s = await AppSettings.load(file());
    expect(s.treeUri, isNull);
    expect(s.migrationDone, isFalse);
  });

  test('corrupt file → defaults, never throws', () async {
    await file().create(recursive: true);
    await file().writeAsString('{broken');
    final s = await AppSettings.load(file());
    expect(s.treeUri, isNull);
    expect(s.migrationDone, isFalse);
  });

  test('writes through and survives reload', () async {
    final s = await AppSettings.load(file());
    await s.setTreeUri('content://tree/x');
    await s.setMigrationDone(true);
    expect(s.treeUri, 'content://tree/x');

    final reloaded = await AppSettings.load(file());
    expect(reloaded.treeUri, 'content://tree/x');
    expect(reloaded.migrationDone, isTrue);

    await reloaded.setTreeUri(null); // re-pick flow clears the grant
    expect((await AppSettings.load(file())).treeUri, isNull);
  });

  test('activeConnector round-trips; unknown value reads as null', () async {
    final s = await AppSettings.load(file());
    expect(s.activeConnector, isNull);

    await s.setActiveConnector('drive');
    expect(s.activeConnector, 'drive');
    expect((await AppSettings.load(file())).activeConnector, 'drive');

    await s.setActiveConnector('dropbox');
    expect((await AppSettings.load(file())).activeConnector, 'dropbox');

    await s.setActiveConnector(null); // disconnect
    expect((await AppSettings.load(file())).activeConnector, isNull);

    // A corrupt/foreign entry is a disconnect, never a crash.
    await file().writeAsString(jsonEncode({'active_connector': 'icloud'}));
    expect((await AppSettings.load(file())).activeConnector, isNull);
  });

  test('corrupt file still recovers activeConnector default', () async {
    await file().create(recursive: true);
    await file().writeAsString('{broken');
    final s = await AppSettings.load(file());
    expect(s.activeConnector, isNull);
    await s.setActiveConnector('drive'); // writable after recovery
    expect((await AppSettings.load(file())).activeConnector, 'drive');
  });
}
