// Settings tab (undesigned-minimal-until-drawn surface): theme choice applied
// live through MaterialApp.themeMode AND persisted through AppSettings, the
// storage row reaching the 3h screen, the licenses page, and the version
// footer. Same harness discipline as shell_test.dart (real IO settles via
// runAsync rounds).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/app_settings.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/main.dart';
import 'package:myrecibook/ui/theme_model.dart';
import 'package:myrecibook/version.dart';

class FakeExtractor implements Extractor {
  @override
  String get mode => 'image';

  @override
  String get modelName => 'fake-model';

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async =>
      {'title': 'unused', 'ingredients': [], 'steps': []};
}

void main() {
  late Directory tmp;
  late LocalFolderStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('myrecibook_settings_tab');
    store = LocalFolderStore(Directory('${tmp.path}/recipes'));
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester, {int rounds = 32}) async {
    for (var i = 0; i < rounds; i++) {
      await tester
          .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Widget app({ThemeModel? themeModel}) => buildApp(
      store: store,
      extractor: FakeExtractor(),
      picker: () async => const [],
      themeModel: themeModel);

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.text('Settings'));
    await settle(tester, rounds: 4);
  }

  ThemeMode? appThemeMode(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;

  test('inert ThemeModel (test-seam default) stays on system', () {
    expect(ThemeModel().mode, ThemeMode.system);
  });

  testWidgets('theme choice reacts live and persists across a relaunch',
      (tester) async {
    final settingsFile = File('${tmp.path}/settings.json');
    final settings =
        (await tester.runAsync(() => AppSettings.load(settingsFile)))!;
    final model = ThemeModel(settings: settings);

    await tester.pumpWidget(app(themeModel: model));
    await settle(tester);
    expect(appThemeMode(tester), ThemeMode.system); // default preserved

    await openSettings(tester);
    await tester.tap(find.text('Dark'));
    await settle(tester, rounds: 4);
    expect(appThemeMode(tester), ThemeMode.dark); // MaterialApp reacted
    expect(Theme.of(tester.element(find.text('Appearance'.toUpperCase())))
            .brightness,
        Brightness.dark);

    // Persisted: the choice survives a reload of the settings file...
    final reloaded =
        (await tester.runAsync(() => AppSettings.load(settingsFile)))!;
    expect(reloaded.themeMode, 'dark');
    // ...and a relaunched ThemeModel boots straight into it.
    expect(ThemeModel(settings: reloaded).mode, ThemeMode.dark);

    await tester.tap(find.text('Light'));
    await settle(tester, rounds: 4);
    expect(appThemeMode(tester), ThemeMode.light);
    expect(
        (await tester.runAsync(() => AppSettings.load(settingsFile)))!
            .themeMode,
        'light');
  });

  testWidgets('corrupt persisted theme boots as system', (tester) async {
    final settingsFile = File('${tmp.path}/settings.json');
    await tester.runAsync(
        () => settingsFile.writeAsString(jsonEncode({'theme_mode': 'sepia'})));
    final settings =
        (await tester.runAsync(() => AppSettings.load(settingsFile)))!;
    expect(ThemeModel(settings: settings).mode, ThemeMode.system);
  });

  testWidgets('storage row shows the truthful summary and opens the 3h screen',
      (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    await openSettings(tester);

    // Inert StorageModel, no folder name → the honest local-only state.
    expect(find.text('This phone'), findsOneWidget);
    await tester.tap(find.text('Where your recipes live'));
    await settle(tester, rounds: 6);
    expect(find.text('Plain files, one per recipe. Yours.'), findsOneWidget);
  });

  testWidgets('licenses page opens; version footer renders', (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    await openSettings(tester);

    expect(find.text('MyReciBook $kAppVersion · you own this copy'),
        findsOneWidget);

    await tester.tap(find.text('Open source licenses'));
    await settle(tester, rounds: 6);
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
