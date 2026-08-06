// Manual entry (5b promise): sheet door → form → saved file shape. The file
// must be source.type "manual", no extraction, no images — and round-trip
// through the store scan back into the cookbook grid.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/main.dart';

/// Never called — manual entry must not touch the extractor.
class ExplodingExtractor implements Extractor {
  int calls = 0;

  @override
  String get mode => 'image';

  @override
  String get modelName => 'fake-model';

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async {
    calls++;
    throw StateError('manual entry must never extract');
  }
}

void main() {
  late Directory tmp;
  late LocalFolderStore store;
  late ExplodingExtractor extractor;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('myrecibook_manual');
    store = LocalFolderStore(Directory('${tmp.path}/recipes'));
    extractor = ExplodingExtractor();
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Widget app() => buildApp(
      store: store, extractor: extractor, picker: () async => const []);

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

  Future<void> openManual(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester, rounds: 6);
    await tester.tap(find.byKey(const Key('import-manual-tile')));
    await settle(tester, rounds: 6);
  }

  testWidgets('sheet shows the manual door with the 5b promise copy',
      (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester, rounds: 6);

    expect(find.text('Type it in yourself'), findsOneWidget);
    expect(find.text('no AI, no cap — always unlimited'), findsOneWidget);
  });

  testWidgets('typed recipe saves as source.type manual, no extraction, '
      'no images, and lands in the cookbook', (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);

    await openManual(tester);
    expect(find.text('Type it in yourself'), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('manual-title')), "Nan's bread");
    await tester.enterText(find.byKey(const Key('manual-servings')), ' 6 loaves ');
    await tester.enterText(
        find.byKey(const Key('manual-ingredients')),
        '2 cups flour\n\n 1 tsp salt \n');
    await tester.enterText(
        find.byKey(const Key('manual-steps')), 'Mix.\nBake.');
    await tester.tap(find.text('Save to cookbook'));
    await settle(tester);

    // Back on the cookbook with the new recipe in the grid (round-trip
    // through listAll proves fromJson tolerates type "manual").
    expect(find.text("Nan's bread"), findsOneWidget);

    final files = savedJsonFiles();
    expect(files, hasLength(1));
    final json =
        jsonDecode(files.single.readAsStringSync()) as Map<String, dynamic>;
    expect((json['source'] as Map)['type'], 'manual');
    expect((json['source'] as Map)['original_images'], isNull);
    expect(json['extraction'], isNull);
    expect(json['title'], "Nan's bread");
    expect((json['servings'] as Map)['raw'], '6 loaves');
    expect([for (final i in json['ingredients'] as List) i['raw']],
        ['2 cups flour', '1 tsp salt']); // blank lines dropped, trimmed
    expect([for (final s in json['steps'] as List) s['raw']], ['Mix.', 'Bake.']);
    expect(extractor.calls, 0); // no AI involved, ever

    // Round-trip pin: the saved file parses back identically.
    final back = Recipe.fromJson(json);
    expect(back.source.type, 'manual');
    expect(back.extraction, isNull);
    expect(jsonEncode(back.toJson()), jsonEncode(json));
  });

  testWidgets('empty title blocks the save with the validator copy',
      (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);

    await openManual(tester);
    await tester.enterText(
        find.byKey(const Key('manual-ingredients')), '2 eggs\n1 cup flour');
    await tester.tap(find.text('Save to cookbook'));
    // Short settle keeps the 4s snackbar alive for the assertion.
    await settle(tester, rounds: 6);

    expect(find.text('empty title'), findsOneWidget);
    expect(savedJsonFiles(), isEmpty);
    expect(find.text('Type it in yourself'), findsOneWidget); // did not pop
  });
}
