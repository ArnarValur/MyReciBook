// End-to-end widget flows against a real LocalFolderStore on a temp dir.
// dart:io futures don't complete under FakeAsync — _settle runs the real
// event loop via runAsync between pumps instead of pumpAndSettle (which
// would deadlock on spinners).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/main.dart';

import '../helpers/fixtures.dart';

class FakeExtractor implements Extractor {
  FakeExtractor(this.outcomes);

  /// Consumed in order; last one repeats. Map = success, exception = throw.
  final List<Object> outcomes;
  int calls = 0;

  @override
  String get mode => 'image';

  @override
  String get modelName => 'fake-model';

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async {
    final o = outcomes[calls < outcomes.length ? calls : outcomes.length - 1];
    calls++;
    if (o is ExtractionException) throw o;
    // Deep copy — the review screen mutates the content map.
    return jsonDecode(jsonEncode(o)) as Map<String, dynamic>;
  }
}

void main() {
  late Directory tmp;
  late LocalFolderStore store;
  late File pick;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('myrecibook_ui_test');
    store = LocalFolderStore(Directory('${tmp.path}/recipes'));
    pick = File('${tmp.path}/pick1.jpg');
    await pick.writeAsBytes([1, 2, 3]);
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Widget app(Extractor extractor) =>
      buildApp(store: store, extractor: extractor, picker: () async => [pick]);

  // Real IO started in the fake zone completes while runAsync pumps the real
  // event loop; the pump then rebuilds with the result.
  // Each round advances roughly one real-IO await step, so rounds must exceed
  // the longest chain (save: mkdir+copy+write, then rescan reads every file).
  // The skin added real-IO steps of its own (bundled-font asset loads, cover
  // Image.file decodes) that consume early rounds — hence 32, not 20.
  Future<void> settle(WidgetTester tester, {int rounds = 32}) async {
    for (var i = 0; i < rounds; i++) {
      await tester
          .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      // Duration advances the fake clock too: route/dialog animations finish.
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Future<void> seed(WidgetTester tester, String id, String title) =>
      tester.runAsync(() => store.save(
            Recipe.assemble(
              id: id,
              content: canned(title: title),
              originalImages: const [],
              importedAt: DateTime.utc(2026, 8, 6),
              extractorModel: 'fake-model',
              extractorMode: 'image',
            ),
            const [],
          ));

  List<File> savedJsonFiles() => !store.root.existsSync()
      ? const []
      : store.root
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

  // Skin flow (3a): the FAB opens the import sheet; the screenshots tile
  // hands off to the injected picker.
  Future<void> startImport(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    await tester.tap(find.byKey(const Key('import-screenshots-tile')));
    await settle(tester);
  }

  testWidgets('empty library sells the first rescue', (tester) async {
    await tester.pumpWidget(app(FakeExtractor([canned()])));
    await settle(tester);
    expect(find.textContaining('Your book is empty'), findsOneWidget);
    expect(find.text('Rescue your first recipe'), findsOneWidget);
  });

  testWidgets('happy import: review, edit title, save to list and disk',
      (tester) async {
    await tester.pumpWidget(app(FakeExtractor([canned()])));
    await settle(tester);

    await startImport(tester);
    expect(find.widgetWithText(TextField, 'Pancakes'), findsOneWidget);

    // D6 pre-save scope: title + any raw line.
    await tester.enterText(
        find.widgetWithText(TextField, 'Pancakes'), 'Better Pancakes');
    await tester.enterText(
        find.widgetWithText(TextField, '1 cup flour'), '2 cups flour');
    await tester.enterText(
        find.widgetWithText(TextField, 'Mix everything.'), 'Whisk everything.');
    await tester.tap(find.text('Save to cookbook'));
    await settle(tester);

    expect(find.text('Better Pancakes'), findsOneWidget);
    final files = savedJsonFiles();
    expect(files, hasLength(1));
    final json =
        jsonDecode(files.single.readAsStringSync()) as Map<String, dynamic>;
    expect(json['title'], 'Better Pancakes');
    expect(json['ingredients'][1]['raw'], '2 cups flour');
    expect(json['steps'][0]['raw'], 'Whisk everything.');
    expect(json['extraction']['mode'], 'image');
  });

  testWidgets('blocked save: empty title writes nothing, stays on review',
      (tester) async {
    await tester.pumpWidget(app(FakeExtractor([canned()])));
    await settle(tester);

    await startImport(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Pancakes'), '');
    await tester.tap(find.text('Save to cookbook'));
    // Validation is synchronous — a short settle keeps the 4s snackbar alive
    // for the assertion (32 rounds × 150ms of fake clock would outlive it).
    await settle(tester, rounds: 6);

    expect(find.text('empty title'), findsOneWidget); // blocking snackbar
    expect(savedJsonFiles(), isEmpty);
    expect(find.text('Recipe rescued'), findsOneWidget); // did not pop
  });

  testWidgets('extraction failure shows retry; retry reaches review',
      (tester) async {
    await tester.pumpWidget(app(FakeExtractor([
      ExtractionException('offline: no route to host'),
      canned(title: 'Waffles'),
    ])));
    await settle(tester);

    await startImport(tester);
    expect(find.text("You're offline"), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await settle(tester);
    expect(find.widgetWithText(TextField, 'Waffles'), findsOneWidget);
  });

  testWidgets('no steps: banner shown, save still succeeds', (tester) async {
    await tester.pumpWidget(app(FakeExtractor([canned(withSteps: false)])));
    await settle(tester);

    await startImport(tester);
    expect(find.textContaining('No steps captured'), findsOneWidget);

    await tester.tap(find.text('Save to cookbook'));
    await settle(tester);
    expect(find.text('Pancakes'), findsOneWidget);
    expect(savedJsonFiles(), hasLength(1));
  });

  testWidgets('detail: editing notes persists to disk', (tester) async {
    await seed(tester, 'seed-1', 'Soup');
    await tester.pumpWidget(app(FakeExtractor([canned()])));
    await settle(tester);

    await tester.tap(find.text('Soup'));
    await settle(tester);
    // The notes card sits below the fold of the detail scroll (collapsing
    // hero + cards); lazy children must be scrolled into existence before
    // enterText can find them. Detail is a CustomScrollView since the
    // 2026-08-06 collapsing-hero change.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await settle(tester);
    await tester.enterText(
        find.byKey(const Key('notes-field')), 'less salt next time');
    await tester.tap(find.text('Save notes'));
    await settle(tester);

    final json = jsonDecode(
            File('${store.root.path}/seed-1.json').readAsStringSync())
        as Map<String, dynamic>;
    expect(json['notes'], 'less salt next time');
  });

  testWidgets('delete: confirm removes from list and disk', (tester) async {
    await seed(tester, 'seed-1', 'Soup');
    await tester.pumpWidget(app(FakeExtractor([canned()])));
    await settle(tester);

    await tester.tap(find.text('Soup'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.delete_rounded));
    await settle(tester);
    // The canonical 6f destructive shape: safe Cancel + filled verb button.
    expect(find.text('Delete recipe?'), findsOneWidget);
    expect(find.text('"Soup" and its images will be removed.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Delete'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await settle(tester);

    expect(find.text('Soup'), findsNothing);
    expect(File('${store.root.path}/seed-1.json').existsSync(), isFalse);
  });
}
