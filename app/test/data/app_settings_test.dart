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

  // ── The backup split (2026-08-27) ──────────────────────────────────────
  // A SAF grant cannot follow the user to another phone, so its pointer must
  // not ride Android's backup. These three pin the mechanism that keeps
  // tree_uri out of the portable file.

  File deviceFile() => File('${tmp.path}/nested/device.json');

  test('tree_uri is written to device.json, never to settings.json', () async {
    final s = await AppSettings.load(file());
    await s.setTreeUri('content://tree/x');
    await s.setThemeMode('dark');

    final portable =
        jsonDecode(await file().readAsString()) as Map<String, dynamic>;
    final device =
        jsonDecode(await deviceFile().readAsString()) as Map<String, dynamic>;

    expect(device['tree_uri'], 'content://tree/x');
    expect(portable.containsKey('tree_uri'), isFalse,
        reason: 'settings.json rides cloud backup — the folder must not');
    // The portable half still carries what SHOULD travel.
    expect(portable['theme_mode'], 'dark');
  });

  test('onboarding_seen lives beside it, so a fresh install replays', () async {
    final s = await AppSettings.load(file());
    expect(s.onboardingSeen, 0);
    await s.setOnboardingSeen(3);

    final device =
        jsonDecode(await deviceFile().readAsString()) as Map<String, dynamic>;
    expect(device['onboarding_seen'], 3);
    expect((await AppSettings.load(file())).onboardingSeen, 3);

    // Wiping the device file alone (what an uninstall does) resets both.
    await deviceFile().delete();
    final fresh = await AppSettings.load(file());
    expect(fresh.onboardingSeen, 0);
    expect(fresh.treeUri, isNull);
  });

  test('a pre-split settings.json is drained on load', () async {
    // Exactly the shape that caused the bug: a restored backup handing a
    // fresh install a folder path it has no permission for.
    await file().create(recursive: true);
    await file().writeAsString(jsonEncode({
      'tree_uri': 'content://tree/old',
      'theme_mode': 'dark',
    }));

    final s = await AppSettings.load(file());
    expect(s.treeUri, 'content://tree/old'); // not lost on upgrade
    expect(s.themeMode, 'dark');

    final portable =
        jsonDecode(await file().readAsString()) as Map<String, dynamic>;
    expect(portable.containsKey('tree_uri'), isFalse,
        reason: 'the next backup must no longer carry it');
    final device =
        jsonDecode(await deviceFile().readAsString()) as Map<String, dynamic>;
    expect(device['tree_uri'], 'content://tree/old');
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

  test('themeMode round-trips; unknown value reads as system', () async {
    final s = await AppSettings.load(file());
    expect(s.themeMode, 'system'); // missing → default

    await s.setThemeMode('dark');
    expect(s.themeMode, 'dark');
    expect((await AppSettings.load(file())).themeMode, 'dark');

    await s.setThemeMode('light');
    expect((await AppSettings.load(file())).themeMode, 'light');

    await s.setThemeMode('system');
    expect((await AppSettings.load(file())).themeMode, 'system');

    // A corrupt/foreign entry is the default, never a crash.
    await file().writeAsString(jsonEncode({'theme_mode': 'sepia'}));
    expect((await AppSettings.load(file())).themeMode, 'system');
  });

  test('corrupt file still recovers themeMode default and stays writable',
      () async {
    await file().create(recursive: true);
    await file().writeAsString('{broken');
    final s = await AppSettings.load(file());
    expect(s.themeMode, 'system');
    await s.setThemeMode('dark'); // writable after recovery
    expect((await AppSettings.load(file())).themeMode, 'dark');
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
