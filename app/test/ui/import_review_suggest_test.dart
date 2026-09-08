// Import tags are suggestions, not attachments (Direction A, 2026-09-03):
// what a link import carries is shown under the draft's tags and lands only
// when tapped. Nothing untapped reaches the saved file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/data/tag_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/domain/recipe_tag.dart';
import 'package:myrecibook/ui/import_review_screen.dart';
import 'package:myrecibook/ui/library_model.dart';
import 'package:myrecibook/ui/tags_model.dart';
import 'package:myrecibook/ui/theme.dart';
import 'package:provider/provider.dart';

class _NoExtractor implements Extractor {
  @override
  String get mode => 'link';
  @override
  String get modelName => 'jsonld';
  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) =>
      throw StateError('prefilled review must not extract');
}

void main() {
  late Directory tmp;
  late LocalFolderStore store;
  late TagsModel tags;

  Future<void> settle(WidgetTester tester, {int rounds = 12}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recibook_suggest');
    store = LocalFolderStore(Directory('${tmp.path}/recipes'));
    tags = TagsModel(store: MemoryTagStore(), library: LibraryModel(store));
    await tags.load();
    // The user already has a decorated "Dessert" — the site's "dessert"
    // must land as that one, not as a twin.
    await tags.create(RecipeTag(name: 'Dessert', icon: 'cake'));
  });

  tearDown(() => tmp.delete(recursive: true));

  Map<String, dynamic> linkContent() => {
        'title': 'Tiramisu',
        'source': {'type': 'link', 'url': 'https://example.com/tiramisu'},
        'tags': ['dessert', 'American', 'Side Dish'],
        'ingredients': [
          {'raw': 'mascarpone', 'confidence': 1.0},
        ],
        'steps': [
          {'raw': 'Layer.', 'confidence': 1.0},
        ],
        'extraction': {'overall_confidence': 1.0, 'needs_review': <String>[]},
      };

  Widget harness() => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LibraryModel(store)),
          ChangeNotifierProvider<TagsModel>.value(value: tags),
        ],
        child: MaterialApp(
          theme: rbLightTheme(),
          home: ImportReviewScreen.prefilled(
            images: const [],
            content: linkContent(),
            extractor: _NoExtractor(),
            pickMore: () async => const [],
            fetchCover: (_) async => null,
          ),
        ),
      );

  testWidgets('incoming tags are offered, not attached', (tester) async {
    await tester.pumpWidget(harness());
    await settle(tester);

    expect(find.text('TAGS'), findsOneWidget, reason: 'nothing on the draft');
    expect(find.text('From the site — tap one to keep it'), findsOneWidget);
    expect(find.byKey(const Key('suggested-tag-dessert')), findsOneWidget);
    expect(find.byKey(const Key('suggested-tag-american')), findsOneWidget);
    expect(find.byKey(const Key('suggested-tag-side dish')), findsOneWidget);
  });

  testWidgets('tapping keeps one, in the user\'s own spelling; only kept '
      'tags are saved', (tester) async {
    await tester.pumpWidget(harness());
    await settle(tester);

    await tester.tap(find.byKey(const Key('suggested-tag-dessert')));
    await tester.pump();
    expect(find.text('TAGS · 1'), findsOneWidget);
    expect(find.byKey(const Key('suggested-tag-dessert')), findsNothing);
    expect(find.text('Dessert'), findsOneWidget, reason: 'your spelling wins');

    await tester.ensureVisible(find.text('Save to cookbook'));
    await tester.pump();
    await tester.tap(find.text('Save to cookbook'));
    // The atomic write advances ~one real-IO step per round (link_cover_test).
    await settle(tester, rounds: 60);

    final saved = (await tester.runAsync(() => store.listAll()))!;
    expect(saved.recipes.single.tags, ['Dessert']);
  });
}
