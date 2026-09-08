// The cookbook's tag strip (Direction A, 2026-09-03): one grid, tiles above
// it, tap a tile to narrow the grid in place. Pins the three things the
// shelf it replaced got wrong — untagged recipes are not stacked apart,
// a recipe is never filed twice, and clearing is one tap on the header.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/main.dart';

class FakeExtractor implements Extractor {
  @override
  String get mode => 'image';

  @override
  String get modelName => 'fake-model';

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async =>
      throw UnimplementedError('tile tests never extract');
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
    tmp = await Directory.systemTemp.createTemp('myrecibook_tiles_test');
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
      {bool favorite = false, List<String> tags = const []}) async {
    final recipe = Recipe.assemble(
      id: id,
      content: canned(title),
      originalImages: const [],
      importedAt: DateTime.utc(2026, 9, 3),
      extractorModel: 'fake-model',
      extractorMode: 'image',
    );
    await tester.runAsync(() =>
        store.save(recipe.copyWith(favorite: favorite, tags: tags), const []));
  }

  Widget app() => buildApp(
      store: store, extractor: FakeExtractor(), picker: () async => const []);

  testWidgets('one grid: tagged and untagged recipes sit together',
      (tester) async {
    await seed(tester, 'r1', 'Pancakes', tags: ['Weeknight']);
    await seed(tester, 'r2', 'Waffles', favorite: true);
    await seed(tester, 'r3', 'Toast');
    await tester.pumpWidget(app());
    await settle(tester);

    expect(find.text('ALL RECIPES · 3'), findsOneWidget);
    expect(find.text('Pancakes'), findsOneWidget);
    expect(find.text('Waffles'), findsOneWidget);
    expect(find.text('Toast'), findsOneWidget);
    // The strip: Favorites first, then the tag the library carries, then
    // the door — no Settings screen needed for any of it.
    expect(find.byKey(const Key('tag-tile-favorites')), findsOneWidget);
    expect(find.byKey(const Key('tag-tile-weeknight')), findsOneWidget);
    expect(find.byKey(const Key('tag-tile-new')), findsOneWidget);
  });

  testWidgets('a tile narrows the grid in place; × and a second tap clear',
      (tester) async {
    await seed(tester, 'r1', 'Pancakes', tags: ['Weeknight']);
    await seed(tester, 'r2', 'Waffles', favorite: true);
    await seed(tester, 'r3', 'Toast');
    await tester.pumpWidget(app());
    await settle(tester);

    await tester.tap(find.byKey(const Key('tag-tile-weeknight')));
    await tester.pump();
    expect(find.text('Pancakes'), findsOneWidget);
    expect(find.text('Toast'), findsNothing);
    // Keyed: the tiles say "1 recipe" too.
    expect(
        tester.widget<Text>(find.byKey(const Key('selection-count'))).data,
        '1 recipe');
    expect(find.byKey(const Key('edit-tag-button')), findsOneWidget);

    // Favorites is a tile like the others, minus the edit door.
    await tester.tap(find.byKey(const Key('tag-tile-favorites')));
    await tester.pump();
    expect(find.text('Waffles'), findsOneWidget);
    expect(find.text('Pancakes'), findsNothing);
    expect(find.byKey(const Key('edit-tag-button')), findsNothing);

    await tester.tap(find.byKey(const Key('clear-selection')));
    await tester.pump();
    expect(find.text('ALL RECIPES · 3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tag-tile-weeknight')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tag-tile-weeknight')));
    await tester.pump();
    expect(find.text('ALL RECIPES · 3'), findsOneWidget);
  });
}
