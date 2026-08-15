// Cookbook grid ⇄ list toggle (Arnar's ask, 2026-08-15): the far end of the
// filter bar switches between the designed 3d cover grid and a compact
// cover-less list; the choice survives a restart through AppSettings.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/app_settings.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/main.dart';
import 'package:myrecibook/ui/cookbook_prefs.dart';
import 'package:myrecibook/ui/widgets/skin.dart';

class FakeExtractor implements Extractor {
  @override
  String get mode => 'image';

  @override
  String get modelName => 'fake-model';

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async =>
      throw UnimplementedError('view tests never extract');
}

Map<String, dynamic> canned(String title) => {
      'title': title,
      'ingredients': [
        {'raw': '2 eggs', 'qty': 2, 'item': 'eggs', 'confidence': 0.95},
      ],
      'steps': [
        {'raw': 'Mix everything.', 'confidence': 0.9},
      ],
      'extraction': {'overall_confidence': 0.9, 'needs_review': <Object?>[]},
    };

void main() {
  late Directory tmp;
  late LocalFolderStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('myrecibook_view_test');
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

  Future<void> seed(WidgetTester tester, String id, String title,
      {bool favorite = false}) async {
    final recipe = Recipe.assemble(
      id: id,
      content: canned(title),
      originalImages: const [],
      importedAt: DateTime.utc(2026, 8, 15),
      extractorModel: 'fake-model',
      extractorMode: 'image',
    );
    await tester.runAsync(() =>
        store.save(favorite ? recipe.copyWith(favorite: true) : recipe, const []));
  }

  Widget app({CookbookPrefs? prefs}) => buildApp(
      store: store,
      extractor: FakeExtractor(),
      picker: () async => const [],
      cookbookPrefs: prefs);

  testWidgets('toggle flips covers grid ⇄ compact list and back',
      (tester) async {
    await seed(tester, 'r1', 'Pancakes');
    await seed(tester, 'r2', 'Waffles', favorite: true);
    await tester.pumpWidget(app());
    await settle(tester);

    // Designed 3d default: the cover grid.
    expect(find.byType(RecipeCover), findsNWidgets(2));
    expect(find.text('Pancakes'), findsOneWidget);

    await tester.tap(find.byKey(const Key('view-toggle')));
    await tester.pump();

    // List form: no cover decodes, titles still there, favorite keeps its
    // heart (one in the list row — the filter chip's heart is a second).
    expect(find.byType(RecipeCover), findsNothing);
    expect(find.text('Pancakes'), findsOneWidget);
    expect(find.text('Waffles'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('view-toggle')));
    await tester.pump();
    expect(find.byType(RecipeCover), findsNWidgets(2));
  });

  testWidgets('choice persists through AppSettings across a restart',
      (tester) async {
    final file = File('${tmp.path}/settings.json');
    final settings = (await tester.runAsync(() => AppSettings.load(file)))!;

    await seed(tester, 'r1', 'Pancakes');
    await tester
        .pumpWidget(app(prefs: CookbookPrefs(settings: settings)));
    await settle(tester);
    await tester.tap(find.byKey(const Key('view-toggle')));
    // Full default rounds: the atomic write (mkdir → write tmp → flush →
    // rename) advances ~one real-IO step per settle round.
    await settle(tester);

    // On disk immediately (best-effort write-through)…
    final onDisk = jsonDecode(
            await tester.runAsync(() => file.readAsString()) as String)
        as Map<String, dynamic>;
    expect(onDisk['cookbook_view'], 'list');

    // …and a fresh load boots straight into the list.
    final reloaded = (await tester.runAsync(() => AppSettings.load(file)))!;
    await tester
        .pumpWidget(app(prefs: CookbookPrefs(settings: reloaded)));
    await settle(tester);
    expect(find.byType(RecipeCover), findsNothing);
    expect(find.text('Pancakes'), findsOneWidget);
  });

  test('parse: only "list" leaves the designed grid default', () {
    expect(CookbookPrefs.parse('list'), CookbookView.list);
    expect(CookbookPrefs.parse('grid'), CookbookView.grid);
    expect(CookbookPrefs.parse('garbage'), CookbookView.grid);
    expect(CookbookPrefs.parse(null), CookbookView.grid);
  });
}
