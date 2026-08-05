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

Map<String, dynamic> canned({String title = 'Pancakes', bool withSteps = true}) =>
    {
      'title': title,
      'ingredients': [
        {'raw': '2 eggs', 'qty': 2, 'item': 'eggs', 'confidence': 0.95},
        {'raw': '1 cup flour', 'confidence': 0.6},
      ],
      'steps': withSteps
          ? [
              {'raw': 'Mix everything.', 'confidence': 0.9},
              {'raw': 'Fry until golden.', 'confidence': 0.9},
            ]
          : [],
      'extraction': {'overall_confidence': 0.9, 'needs_review': []},
    };

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
  Future<void> settle(WidgetTester tester, {int rounds = 20}) async {
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

  testWidgets('empty library points at the + button', (tester) async {
    await tester.pumpWidget(app(FakeExtractor([canned()])));
    await settle(tester);
    expect(find.textContaining('No recipes yet'), findsOneWidget);
  });

  testWidgets('happy import: review, edit title, save to list and disk',
      (tester) async {
    await tester.pumpWidget(app(FakeExtractor([canned()])));
    await settle(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    expect(find.widgetWithText(TextField, 'Pancakes'), findsOneWidget);

    // D6 pre-save scope: title + any raw line.
    await tester.enterText(
        find.widgetWithText(TextField, 'Pancakes'), 'Better Pancakes');
    await tester.enterText(
        find.widgetWithText(TextField, '1 cup flour'), '2 cups flour');
    await tester.enterText(
        find.widgetWithText(TextField, 'Mix everything.'), 'Whisk everything.');
    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(find.widgetWithText(ListTile, 'Better Pancakes'), findsOneWidget);
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

    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Pancakes'), '');
    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(find.text('empty title'), findsOneWidget); // blocking snackbar
    expect(savedJsonFiles(), isEmpty);
    expect(find.text('Review import'), findsOneWidget); // did not pop
  });

  testWidgets('extraction failure shows retry; retry reaches review',
      (tester) async {
    await tester.pumpWidget(app(FakeExtractor([
      ExtractionException('offline: no route to host'),
      canned(title: 'Waffles'),
    ])));
    await settle(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    expect(find.textContaining('Offline'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(find.widgetWithText(TextField, 'Waffles'), findsOneWidget);
  });

  testWidgets('no steps: banner shown, save still succeeds', (tester) async {
    await tester.pumpWidget(app(FakeExtractor([canned(withSteps: false)])));
    await settle(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    expect(find.textContaining('No steps captured'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.widgetWithText(ListTile, 'Pancakes'), findsOneWidget);
    expect(savedJsonFiles(), hasLength(1));
  });

  testWidgets('detail: editing notes persists to disk', (tester) async {
    await seed(tester, 'seed-1', 'Soup');
    await tester.pumpWidget(app(FakeExtractor([canned()])));
    await settle(tester);

    await tester.tap(find.text('Soup'));
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
    await tester.tap(find.byIcon(Icons.delete));
    await settle(tester);
    await tester.tap(find.text('Delete'));
    await settle(tester);

    expect(find.text('Soup'), findsNothing);
    expect(File('${store.root.path}/seed-1.json').existsSync(), isFalse);
  });
}
