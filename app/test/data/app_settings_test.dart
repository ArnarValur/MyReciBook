// AppSettings: read-once, write-through JSON file; missing/corrupt → defaults.

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
}
