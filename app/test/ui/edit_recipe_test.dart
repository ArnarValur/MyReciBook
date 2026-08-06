// Post-save edit via the review screen (D6 as amended 2026-08-06): the saved
// recipe reopens in review, saves back over the same file. Text-level only —
// the envelope (source, extraction stamps, notes, favorite) must survive, and
// no extraction call may fire. Same real-IO settle harness as app_flow_test.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/main.dart';
import 'package:myrecibook/ui/grocery_model.dart';
import 'package:provider/provider.dart';

class NoCallExtractor implements Extractor {
  int calls = 0;

  @override
  String get mode => 'image';

  @override
  String get modelName => 'fake-model';

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async {
    calls++;
    throw StateError('edit mode must never extract');
  }
}

void main() {
  late Directory tmp;
  late LocalFolderStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('myrecibook_edit_test');
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

  Widget app(Extractor extractor) =>
      buildApp(store: store, extractor: extractor, picker: () async => []);

  Future<void> seed() => store.save(
        const Recipe(
          schemaVersion: 1,
          id: 'e1',
          title: 'Soup',
          source: RecipeSource(
              type: 'screenshot', importedAt: '2026-08-06T00:00:00.000Z'),
          ingredients: [
            Ingredient(raw: '2 carrots', qty: 2, item: 'carrots', confidence: 0.95),
            Ingredient(raw: '1 cup broth', confidence: 0.9),
          ],
          steps: [RecipeStep(raw: 'Simmer.', confidence: 0.9)],
          notes: 'keep me',
          favorite: true,
          extraction: Extraction(
              model: 'orig-model',
              mode: 'image',
              extractedAt: '2026-08-06T00:00:00.000Z'),
        ),
        const [],
      );

  testWidgets('edit: reopen in review, save back — envelope preserved',
      (tester) async {
    await tester.runAsync(seed);
    final extractor = NoCallExtractor();
    await tester.pumpWidget(app(extractor));
    await settle(tester);

    await tester.tap(find.text('Soup'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('edit-button')));
    await settle(tester);

    expect(find.text('Edit recipe'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Save changes'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Root Soup');
    await tester.enterText(
        find.widgetWithText(TextField, '1 cup broth'), '1 cup stock');
    await tester.tap(find.text('Save changes'));
    await settle(tester);

    // Back on detail, updated in place.
    expect(find.text('Root Soup'), findsWidgets);

    final loaded = await tester.runAsync(() => store.load('e1'));
    expect(loaded!.title, 'Root Soup');
    expect(loaded.ingredients[0].raw, '2 carrots');
    expect(loaded.ingredients[0].qty, 2); // parsed fields untouched (D6)
    expect(loaded.ingredients[1].raw, '1 cup stock');
    expect(loaded.notes, 'keep me');
    expect(loaded.favorite, isTrue);
    expect(loaded.extraction?.model, 'orig-model'); // rule 2: never re-stamped
    expect(loaded.source.importedAt, '2026-08-06T00:00:00.000Z');
    expect(extractor.calls, 0);
  });

  testWidgets('edit re-keys the grocery list when a raw-named line changes',
      (tester) async {
    await tester.runAsync(seed);
    await tester.pumpWidget(app(NoCallExtractor()));
    await settle(tester);

    await tester.tap(find.text('Soup'));
    await settle(tester);
    await tester.tap(find.text('Grocery'));
    await settle(tester, rounds: 6);

    await tester.tap(find.byKey(const Key('edit-button')));
    await settle(tester);
    // Item-less line: its grocery key derives from raw, so the rename must
    // re-key the list row via the detail screen's syncRecipe wiring.
    await tester.enterText(
        find.widgetWithText(TextField, '1 cup broth'), '1 cup stock');
    await tester.tap(find.text('Save changes'));
    await settle(tester);

    final grocery = Provider.of<GroceryModel>(
        tester.element(find.byType(MaterialApp)),
        listen: false);
    final keys = [for (final i in grocery.items) i.key];
    expect(keys, contains('1 cup stock'));
    expect(keys, isNot(contains('1 cup broth')));
    expect(keys, contains('carrots'));
  });
}
