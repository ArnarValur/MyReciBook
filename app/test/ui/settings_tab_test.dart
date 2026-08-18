// Settings tab (6a, turn 6): the segmented theme control applied live through
// MaterialApp.themeMode AND persisted through AppSettings, the truthful
// storage row reaching the 6e Storage screen, the licenses page, and the
// version-only footer (no ownership claim until a receipt exists). Same
// harness discipline as shell_test.dart (real IO settles via runAsync rounds).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/app_settings.dart';
import 'package:myrecibook/data/crash_log.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/domain/units.dart';
import 'package:myrecibook/main.dart';
import 'package:myrecibook/ui/settings_tab.dart';
import 'package:myrecibook/ui/theme_model.dart';
import 'package:myrecibook/ui/units_model.dart';
import 'package:myrecibook/version.dart';

class FakeExtractor implements Extractor {
  @override
  String get mode => 'image';

  @override
  String get modelName => 'fake-model';

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async =>
      {'title': 'unused', 'ingredients': <Object?>[], 'steps': <Object?>[]};
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

  Widget app(
          {ThemeModel? themeModel,
          UnitsModel? unitsModel,
          CrashLog? crashLog}) =>
      buildApp(
          store: store,
          extractor: FakeExtractor(),
          picker: () async => const [],
          themeModel: themeModel,
          unitsModel: unitsModel,
          crashLog: crashLog);

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.text('Settings'));
    await settle(tester, rounds: 8);
  }

  ThemeMode? appThemeMode(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;

  test('inert ThemeModel (test-seam default) stays on system', () {
    expect(ThemeModel().mode, ThemeMode.system);
  });

  FontWeight? segmentWeight(WidgetTester tester, String label) =>
      tester.widget<Text>(find.text(label)).style?.fontWeight;

  testWidgets('segmented theme control reacts live and persists across a '
      'relaunch', (tester) async {
    final settingsFile = File('${tmp.path}/settings.json');
    final settings =
        (await tester.runAsync(() => AppSettings.load(settingsFile)))!;
    final model = ThemeModel(settings: settings);

    await tester.pumpWidget(app(themeModel: model));
    await settle(tester);
    expect(appThemeMode(tester), ThemeMode.system); // default preserved

    await openSettings(tester);
    // Active segment carries the check + w600; the others stay quiet.
    // Two checks total on the tab: one per segmented control (Theme + Units).
    expect(segmentWeight(tester, 'System'), FontWeight.w600);
    expect(segmentWeight(tester, 'Dark'), FontWeight.w500);
    expect(
        find.descendant(
            of: find.byType(SettingsTab),
            matching: find.byIcon(Icons.check_rounded)),
        findsNWidgets(2));

    await tester.tap(find.text('Dark'));
    await settle(tester, rounds: 8);
    expect(appThemeMode(tester), ThemeMode.dark); // MaterialApp reacted
    expect(
        Theme.of(tester.element(find.text('Theme'.toUpperCase()))).brightness,
        Brightness.dark);
    expect(segmentWeight(tester, 'Dark'), FontWeight.w600);
    expect(segmentWeight(tester, 'System'), FontWeight.w500);
    expect(
        find.descendant(
            of: find.byType(SettingsTab),
            matching: find.byIcon(Icons.check_rounded)),
        findsNWidgets(2)); // the pill moved, it didn't multiply

    // Persisted: the choice survives a reload of the settings file...
    final reloaded =
        (await tester.runAsync(() => AppSettings.load(settingsFile)))!;
    expect(reloaded.themeMode, 'dark');
    // ...and a relaunched ThemeModel boots straight into it.
    expect(ThemeModel(settings: reloaded).mode, ThemeMode.dark);

    await tester.tap(find.text('Light'));
    await settle(tester, rounds: 8);
    expect(appThemeMode(tester), ThemeMode.light);
    expect(
        (await tester.runAsync(() => AppSettings.load(settingsFile)))!
            .themeMode,
        'light');
  });

  testWidgets('segmented units control reacts live and persists across a '
      'relaunch', (tester) async {
    final settingsFile = File('${tmp.path}/settings.json');
    final settings =
        (await tester.runAsync(() => AppSettings.load(settingsFile)))!;
    final model = UnitsModel(settings: settings);

    await tester.pumpWidget(app(unitsModel: model));
    await settle(tester);
    await openSettings(tester);

    // Default: nothing converts — "As written" carries the active pill.
    expect(segmentWeight(tester, 'As written'), FontWeight.w600);
    expect(segmentWeight(tester, 'Metric'), FontWeight.w500);

    await tester.tap(find.text('Metric'));
    await settle(tester, rounds: 8);
    expect(model.system, UnitSystem.metric);
    expect(segmentWeight(tester, 'Metric'), FontWeight.w600);
    expect(segmentWeight(tester, 'As written'), FontWeight.w500);

    // Persisted: the choice survives a reload of the settings file...
    final reloaded =
        (await tester.runAsync(() => AppSettings.load(settingsFile)))!;
    expect(reloaded.units, 'metric');
    // ...and a relaunched UnitsModel boots straight into it.
    expect(UnitsModel(settings: reloaded).system, UnitSystem.metric);
  });

  test('inert UnitsModel (test-seam default) stays as-written', () {
    expect(UnitsModel().system, UnitSystem.asWritten);
  });

  test('corrupt persisted units boots as as-written', () async {
    final settingsFile = File('${tmp.path}/settings.json');
    await settingsFile.writeAsString(jsonEncode({'units': 'cubits'}));
    final settings = await AppSettings.load(settingsFile);
    expect(UnitsModel(settings: settings).system, UnitSystem.asWritten);
  });

  testWidgets('corrupt persisted theme boots as system', (tester) async {
    final settingsFile = File('${tmp.path}/settings.json');
    await tester.runAsync(
        () => settingsFile.writeAsString(jsonEncode({'theme_mode': 'sepia'})));
    final settings =
        (await tester.runAsync(() => AppSettings.load(settingsFile)))!;
    expect(ThemeModel(settings: settings).mode, ThemeMode.system);
  });

  testWidgets('storage row shows the truthful caption and opens the 6e screen',
      (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    await openSettings(tester);

    // Inert StorageModel → the honest local-only caption, nothing more.
    expect(find.text('Where your recipes live'), findsOneWidget);
    expect(find.text('This phone'), findsOneWidget);
    expect(find.textContaining('synced'), findsNothing);
    await tester.tap(find.text('Where your recipes live'));
    await settle(tester, rounds: 6);
    expect(find.text('Plain files, one per recipe. Yours.'), findsOneWidget);
  });

  testWidgets('licenses page opens; footer is version-only — no ownership '
      'claim without a receipt', (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    await openSettings(tester);

    expect(find.text('MyReciBook $kAppVersion'), findsOneWidget);
    expect(find.textContaining('you own this copy'), findsNothing);

    await tester.tap(find.text('Open-source licenses'));
    await settle(tester, rounds: 6);
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('footer long-press opens the error log door — honest empty '
      'state', (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    await openSettings(tester);

    await tester.longPress(find.text('MyReciBook $kAppVersion'));
    await settle(tester, rounds: 8);
    expect(find.text('Error log'), findsOneWidget);
    expect(find.text('No captured errors.'), findsOneWidget);
    // empty log offers no Clear/Copy — nothing that pretends to do something
    expect(find.text('Copy all'), findsNothing);
    expect(find.text('Clear'), findsNothing);
  });

  testWidgets('error log door lists captured errors and Clear empties it',
      (tester) async {
    final log = CrashLog.inert();
    await log.record('NullPointerException: sky fell', null);
    await tester.pumpWidget(app(crashLog: log));
    await settle(tester);
    await openSettings(tester);

    await tester.longPress(find.text('MyReciBook $kAppVersion'));
    await settle(tester, rounds: 8);
    expect(find.text('Error log (1)'), findsOneWidget);
    expect(find.text('NullPointerException: sky fell'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await settle(tester, rounds: 8);
    expect(log.count, 0);
    // reopened: honest empty state
    await tester.longPress(find.text('MyReciBook $kAppVersion'));
    await settle(tester, rounds: 8);
    expect(find.text('No captured errors.'), findsOneWidget);
  });
}
