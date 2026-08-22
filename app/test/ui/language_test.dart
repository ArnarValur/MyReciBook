// Interface language. Two halves, because the control is deliberately not on
// screen yet: the PICKER is exercised directly (it works, and must keep
// working while it waits), and the SETTINGS TAB is checked for the opposite —
// that it shows no language row while there is nothing to choose between.
// Arnar 2026-08-22: never show the selection until a language is finished.
// Same harness discipline as settings_tab_test.dart.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/app_settings.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/app_language.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/main.dart';
import 'package:myrecibook/ui/language_model.dart';
import 'package:myrecibook/ui/language_screen.dart';
import 'package:myrecibook/ui/theme.dart';
import 'package:myrecibook/l10n/l10n.dart';
import 'package:provider/provider.dart';

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

  /// The picker on its own, no Settings tab in front of it.
  Widget pickerOnly(LanguageModel model) => ChangeNotifierProvider.value(
        value: model,
        child: Consumer<LanguageModel>(
          builder: (_, m, _) => MaterialApp(
            // TokenCard reads the RbTheme extension — a bare ThemeData has
            // none and the screen throws before it draws anything.
            theme: rbLightTheme(),
            locale: m.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: kOfferedLocales,
            home: const LanguageScreen(),
          ),
        ),
      );

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

  testWidgets('Settings shows a language row only when there is a choice',
      (tester) async {
    await tester.pumpWidget(app(null));
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester, rounds: 8);

    // Not "is it hidden today" — the row must track the invariant, so this
    // keeps holding the day a language is finished and the flag flips.
    expect(find.byKey(const Key('settings-language-row')),
        kLanguageChoiceExists ? findsOneWidget : findsNothing);
  });

  testWidgets('the picker lists exactly the finished languages, in endonyms',
      (tester) async {
    final model = LanguageModel();
    await tester.pumpWidget(pickerOnly(model));
    await tester.pumpAndSettle();

    for (final l in kOfferedLanguages) {
      final label = l == AppLanguage.system ? 'System' : appLanguageEndonym(l);
      expect(find.text(label), findsOneWidget, reason: '$label is missing');
    }
    // A language with an .arb file but not finished must NOT be listed.
    expect(find.text('Íslenska'),
        kOfferedLanguages.contains(AppLanguage.icelandic)
            ? findsOneWidget
            : findsNothing);
    // One check, on the active choice — System until anyone picks.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('picking a language moves the model and the check',
      (tester) async {
    final settingsFile = File('${tmp.path}/settings.json');
    final settings =
        (await tester.runAsync(() => AppSettings.load(settingsFile)))!;
    final model = LanguageModel(settings: settings);

    await tester.pumpWidget(pickerOnly(model));
    await tester.pumpAndSettle();
    expect(model.locale, isNull); // follow the phone, the default

    await tester.tap(find.text('English'));
    // settle, not pumpAndSettle: the write to settings.json is real IO and
    // only runs inside runAsync rounds.
    await settle(tester, rounds: 8);
    expect(model.language, AppLanguage.english);
    expect(model.locale, const Locale('en'));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget); // moved, not multiplied

    // Persisted: the choice survives a reload of the settings file...
    final reloaded =
        (await tester.runAsync(() => AppSettings.load(settingsFile)))!;
    expect(reloaded.language, 'en');
    // ...and a relaunched LanguageModel boots straight into it.
    expect(LanguageModel(settings: reloaded).language, AppLanguage.english);

    // Back to System: the locale goes null again.
    await tester.tap(find.text('System'));
    await settle(tester, rounds: 8);
    expect(model.locale, isNull);
  });
}
