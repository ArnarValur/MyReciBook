// Batch import end-to-end (3a segmented choice → 3b queue → review-now →
// cookbook) plus the drawer badge and manual-entry door. Same harness
// discipline as app_flow_test.dart: real IO settles via runAsync rounds.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/main.dart';

import '../helpers/fixtures.dart' show notARecipe;

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

Map<String, dynamic> canned({
  String title = 'Pancakes',
  double overall = 0.9,
  List<String> needsReview = const [],
}) =>
    {
      'title': title,
      'ingredients': [
        {'raw': '2 eggs', 'qty': 2, 'item': 'eggs', 'confidence': 0.95},
        {'raw': '1 cup flour', 'confidence': 0.95},
      ],
      'steps': [
        {'raw': 'Mix everything.', 'confidence': 0.9},
      ],
      'extraction': {'overall_confidence': overall, 'needs_review': needsReview},
    };

void main() {
  late Directory tmp;
  late LocalFolderStore store;
  late List<File> picks;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('myrecibook_batch_flow');
    store = LocalFolderStore(Directory('${tmp.path}/recipes'));
    picks = [];
    for (var i = 1; i <= 3; i++) {
      final f = File('${tmp.path}/pick$i.jpg');
      await f.writeAsBytes([i]);
      picks.add(f);
    }
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Widget app(Extractor extractor, {List<File>? picked}) => buildApp(
      store: store,
      extractor: extractor,
      picker: () async => picked ?? picks);

  Future<void> settle(WidgetTester tester, {int rounds = 32}) async {
    for (var i = 0; i < rounds; i++) {
      await tester
          .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  List<File> savedJsonFiles() => !store.root.existsSync()
      ? const []
      : store.root
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

  Map<String, dynamic> savedJson(File f) =>
      jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;

  /// FAB → sheet → screenshots tile. With ≥2 picks the sheet stays open on
  /// the segmented choice instead of popping.
  Future<void> openSheetAndPick(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester, rounds: 6);
    await tester.tap(find.byKey(const Key('import-screenshots-tile')));
    await settle(tester, rounds: 6);
  }

  testWidgets('≥2 picks: segmented choice shown, one-recipe path unchanged',
      (tester) async {
    await tester.pumpWidget(app(FakeExtractor([canned()]),
        picked: [picks[0], picks[1]]));
    await settle(tester);

    await openSheetAndPick(tester);
    // Designed copy (3a), counts live.
    expect(find.text('One recipe · 2 shots'), findsOneWidget);
    expect(find.text('2 separate recipes'), findsOneWidget);
    expect(find.text('Rescue as one recipe'), findsOneWidget);

    // Default = one recipe: CTA hands both shots to the single review flow.
    await tester.tap(find.byKey(const Key('import-rescue-cta')));
    await settle(tester);
    expect(find.text('Recipe rescued'), findsOneWidget);
    expect(find.text('Original screenshots · 2'), findsOneWidget);
  });

  testWidgets('CTA label mirrors the segmented choice', (tester) async {
    await tester.pumpWidget(app(FakeExtractor([canned()]),
        picked: [picks[0], picks[1], picks[2]]));
    await settle(tester);

    await openSheetAndPick(tester);
    expect(find.text('Rescue as one recipe'), findsOneWidget);
    await tester.tap(find.byKey(const Key('batch-separate')));
    await tester.pump();
    expect(find.text('Rescue 3 recipes'), findsOneWidget);
    await tester.tap(find.byKey(const Key('batch-one-recipe')));
    await tester.pump();
    expect(find.text('Rescue as one recipe'), findsOneWidget);
  });

  testWidgets(
      'batch e2e: mixed outcomes → queue states → review-now → retry → cookbook',
      (tester) async {
    final extractor = FakeExtractor([
      canned(title: 'Salmon', overall: 0.92, needsReview: ['ingredients[1]']),
      canned(title: 'Pasta', overall: 0.5, needsReview: ['ingredients[0]']),
      ExtractionException('offline: no route to host'),
      canned(title: 'Waffles'), // consumed by the retry
    ]);
    await tester.pumpWidget(app(extractor));
    await settle(tester);

    await openSheetAndPick(tester);
    await tester.tap(find.byKey(const Key('batch-separate')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('import-rescue-cta')));
    await settle(tester, rounds: 48);

    // Queue screen (3b): per-item designed states.
    expect(find.text('Recipes rescued'), findsOneWidget);
    expect(find.text('Salmon'), findsOneWidget);
    expect(find.text('saved · looked complete'), findsOneWidget);
    expect(find.text('Pasta'), findsOneWidget);
    expect(find.text('1 line needs your eyes'), findsOneWidget);
    expect(find.text('offline · retry when connected'), findsOneWidget);
    expect(find.text('Review flagged · 1'), findsOneWidget);
    expect(
        find.text(
            'Not a recipe? We skip it and say so — no junk lands in your book.'),
        findsOneWidget);

    // High-confidence auto-save landed on disk WITH its review-later flag.
    var files = savedJsonFiles();
    expect(files, hasLength(1));
    final salmon = savedJson(files.single);
    expect(salmon['title'], 'Salmon');
    expect(salmon['extraction']['needs_review'], ['ingredients[1]']);

    // Review-now: prefilled from the held extraction — no new AI call.
    final callsBefore = extractor.calls;
    await tester.tap(find.text('Review'));
    await settle(tester, rounds: 8);
    expect(find.text('Recipe rescued'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Pasta'), findsOneWidget);
    expect(extractor.calls, callsBefore);

    await tester.enterText(
        find.widgetWithText(TextField, 'Pasta'), 'Pasta, checked');
    await tester.tap(find.text('Save to cookbook'));
    await settle(tester, rounds: 48);

    // Back on the queue: the item flipped to saved-by-you.
    expect(find.text('saved · you checked it'), findsOneWidget);
    expect(find.text('Review flagged · 1'), findsNothing);
    expect(savedJsonFiles(), hasLength(2));

    // Retry the transport failure → sequential worker → auto-saved.
    await tester.tap(find.text('Retry'));
    await settle(tester, rounds: 48);
    expect(find.text('Waffles'), findsOneWidget);
    expect(find.text('saved · looked complete'), findsNWidgets(2));

    files = savedJsonFiles();
    expect(files, hasLength(3));
    expect([for (final f in files) savedJson(f)['title']],
        containsAll(['Salmon', 'Pasta, checked', 'Waffles']));

    // Done → back to the cookbook; auto-saves are already in the grid.
    await tester.tap(find.text('Done'));
    await settle(tester, rounds: 8);
    expect(find.text('Salmon'), findsOneWidget);
    expect(find.text('Waffles'), findsOneWidget);
  });

  testWidgets('not-a-recipe skips honestly; nothing lands in the book',
      (tester) async {
    await tester.pumpWidget(app(
        FakeExtractor([notARecipe(), canned(title: 'Soup')]),
        picked: [picks[0], picks[1]]));
    await settle(tester);

    await openSheetAndPick(tester);
    await tester.tap(find.byKey(const Key('batch-separate')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('import-rescue-cta')));
    await settle(tester, rounds: 48);

    expect(find.text('not a recipe — skipped, nothing saved'), findsOneWidget);
    expect(find.text('Soup'), findsOneWidget);
    final files = savedJsonFiles();
    expect(files, hasLength(1));
    expect(savedJson(files.single)['title'], 'Soup');
  });

  testWidgets(
      'Queue tab badge counts attention items live; tab shows the batch screen',
      (tester) async {
    await tester.pumpWidget(app(
        FakeExtractor([
          canned(title: 'Pasta', overall: 0.5), // held
          ExtractionException('offline: x'), // failed
        ]),
        picked: [picks[0], picks[1]]));
    await settle(tester);

    await openSheetAndPick(tester);
    await tester.tap(find.byKey(const Key('batch-separate')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('import-rescue-cta')));
    await settle(tester, rounds: 48);

    // Leave the pushed queue: badge on the bar's Queue tab (2026-08-06
    // reshape — the count moved from the drawer row) = needsReview+failed = 2.
    await tester.tap(find.text('Hide'));
    await settle(tester, rounds: 6);
    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // The tab shows the live batch screen, not a dead surface.
    await tester.tap(find.text('Queue'));
    await settle(tester, rounds: 6);
    expect(find.text('Review flagged · 1'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
