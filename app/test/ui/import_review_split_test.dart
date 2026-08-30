// Split-line grouping in review (handoff change 1): ingredients sharing a
// line_id render their source line ONCE with the parsed children beneath it,
// and one confirm clears every entry of the line.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/data/tag_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/ui/import_review_screen.dart';
import 'package:myrecibook/ui/library_model.dart';
import 'package:myrecibook/ui/tags_model.dart';
import 'package:myrecibook/ui/theme.dart';
import 'package:provider/provider.dart';

class _NoExtractor implements Extractor {
  @override
  String get mode => 'image';
  @override
  String get modelName => 'test';
  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) =>
      throw StateError('prefilled review must not extract');
}

const _sharedRaw = '1 teaspoon each of soda Cream of tarter & baking powder';

Map<String, dynamic> _content({List<String> needsReview = const []}) => {
      'title': 'Filled Cookies',
      'ingredients': [
        {
          'raw': _sharedRaw,
          'line_id': 'l7',
          'qty': 1,
          'unit': 'teaspoon',
          'item': 'soda',
          'confidence': 1.0,
        },
        {
          'raw': _sharedRaw,
          'line_id': 'l7',
          'qty': 1,
          'unit': 'teaspoon',
          'item': 'cream of tartar',
          'confidence': 1.0,
        },
        {
          'raw': _sharedRaw,
          'line_id': 'l7',
          'qty': 1,
          'unit': 'teaspoon',
          'item': 'baking powder',
          'confidence': 1.0,
        },
        {'raw': '8 cups of flour', 'line_id': 'l8', 'confidence': 1.0},
      ],
      'steps': [
        {'raw': 'Mix and bake.', 'confidence': 1.0},
      ],
      'extraction': {
        'overall_confidence': 1.0,
        'needs_review': needsReview,
      },
    };

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recibook_split_test');
  });

  tearDown(() => tmp.delete(recursive: true));

  Widget harness(Map<String, dynamic> content) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) =>
                  LibraryModel(LocalFolderStore(Directory('${tmp.path}/r')))),
          ChangeNotifierProvider(
              create: (ctx) => TagsModel(
                    store: MemoryTagStore(),
                    library: ctx.read<LibraryModel>(),
                  )),
        ],
        child: MaterialApp(
          theme: rbLightTheme(),
          home: ImportReviewScreen.prefilled(
            images: const [],
            content: content,
            extractor: _NoExtractor(),
            pickMore: () async => const [],
          ),
        ),
      );

  testWidgets('shared line_id: source line renders once, children beneath',
      (tester) async {
    await tester.pumpWidget(harness(_content()));
    await tester.pump();

    expect(find.text(_sharedRaw), findsOneWidget);
    expect(find.byKey(const Key('split-child-0')), findsOneWidget);
    expect(find.byKey(const Key('split-child-2')), findsOneWidget);
    expect(find.textContaining('1 teaspoon cream of tartar'), findsOneWidget);
    // The un-split neighbour still renders as a plain row.
    expect(find.text('8 cups of flour'), findsOneWidget);
  });

  testWidgets('one confirm chip clears the whole line', (tester) async {
    await tester.pumpWidget(harness(_content(needsReview: [
      'ingredients[0]',
      'ingredients[1]',
      'ingredients[2]',
    ])));
    await tester.pump();

    // One chip for the run — not three.
    expect(find.byKey(const Key('confirm-ingredient-0')), findsOneWidget);
    expect(find.byKey(const Key('confirm-ingredient-1')), findsNothing);

    await tester.tap(find.byKey(const Key('confirm-ingredient-0')));
    await tester.pump();
    expect(find.byKey(const Key('confirm-ingredient-0')), findsNothing);
  });
}
