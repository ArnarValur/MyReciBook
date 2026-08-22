// Interface language: the Settings pill changes MaterialApp.locale live, the
// strings actually redraw in the chosen language, and the choice survives a
// relaunch. Same harness discipline as settings_tab_test.dart.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/app_settings.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/app_language.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/main.dart';
import 'package:myrecibook/ui/language_model.dart';

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
    tmp = await Directory.systemTemp.createTemp('myrecibook_language');
    store = LocalFolderStore(Directory('${tmp.path}/recipes'));
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester, {int rounds = 32}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Widget app(LanguageModel? model) => buildApp(
      store: store,
      extractor: FakeExtractor(),
      picker: () async => const [],
      languageModel: model);

  Locale? appLocale(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale;

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('settings-language-row')));
    await settle(tester, rounds: 8);
  }

  test('inert LanguageModel (test-seam default) follows the phone', () {
    final model = LanguageModel();
    expect(model.language, AppLanguage.system);
    expect(model.locale, isNull); // null hands resolution back to the platform
  });

  test('an unknown or dropped saved language reads as follow-the-phone', () {
    expect(parseAppLanguage('kl'), AppLanguage.system);
    expect(parseAppLanguage(null), AppLanguage.system);
    expect(parseAppLanguage(''), AppLanguage.system);
    expect(parseAppLanguage('nb'), AppLanguage.norwegianBokmal);
    expect(parseAppLanguage('is'), AppLanguage.icelandic);
    expect(parseAppLanguage('pl'), AppLanguage.polish);
  });

  test('the settings string and the locale code never drift', () {
    for (final l in kAppLanguages) {
      if (l == AppLanguage.system) continue;
      expect(appLanguageLocale(l)!.languageCode, appLanguageName(l));
    }
  });

  test('every language round-trips through the settings string', () {
    for (final l in kAppLanguages) {
      expect(parseAppLanguage(appLanguageName(l)), l);
    }
  });

  test('endonyms are distinct — the picker must never show a name twice', () {
    final names = [for (final l in kAppLanguages) appLanguageEndonym(l)];
    expect(names.toSet().length, names.length);
  });

  test('every offered language is one the parser knows', () {
    for (final l in kOfferedLanguages) {
      expect(parseAppLanguage(appLanguageName(l)), l);
    }
  });

  testWidgets('the language pill redraws the app and persists across a '
      'relaunch', (tester) async {
    final settingsFile = File('${tmp.path}/settings.json');
    final settings =
        (await tester.runAsync(() => AppSettings.load(settingsFile)))!;
    final model = LanguageModel(settings: settings);

    await tester.pumpWidget(app(model));
    await settle(tester);
    expect(appLocale(tester), isNull); // default preserved: follow the phone

    await tester.tap(find.text('Settings'));
    await settle(tester, rounds: 8);
    expect(find.text('Theme'.toUpperCase()), findsOneWidget);

    // The row reads 'System' until a language is chosen.
    await openPicker(tester);
    // Only complete languages are offered — a half-translated one is worse
    // than none. Polski has an .arb file and is deliberately absent.
    expect(find.text('Íslenska'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Polski'), findsNothing);

    await tester.tap(find.text('Íslenska'));
    await settle(tester, rounds: 8);
    expect(appLocale(tester), const Locale('is'));
    // The picker's own title redrew, and the endonyms did NOT — a language
    // names itself no matter which language the app is in.
    expect(find.text('Tungumál'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    Navigator.of(tester.element(find.text('Tungumál'))).pop();
    await settle(tester, rounds: 8);

    // The section labels are the proof the strings redrew, not just the state.
    expect(find.text('Þema'.toUpperCase()), findsOneWidget);
    expect(find.text('Einingar'.toUpperCase()), findsOneWidget);
    expect(find.text('Theme'.toUpperCase()), findsNothing);
    // ...and the Settings row now names the chosen language.
    expect(find.text('Íslenska'), findsOneWidget);

    // Persisted: the choice survives a reload of the settings file...
    final reloaded =
        (await tester.runAsync(() => AppSettings.load(settingsFile)))!;
    expect(reloaded.language, 'is');
    // ...and a relaunched LanguageModel boots straight into it.
    expect(LanguageModel(settings: reloaded).language, AppLanguage.icelandic);

    // Back to System: the locale goes null again, English comes back.
    await openPicker(tester);
    await tester.tap(find.text('Kerfi'));
    await settle(tester, rounds: 8);
    Navigator.of(tester.element(find.text('English'))).pop();
    await settle(tester, rounds: 8);
    expect(appLocale(tester), isNull);
    expect(find.text('Theme'.toUpperCase()), findsOneWidget);
  });
}
