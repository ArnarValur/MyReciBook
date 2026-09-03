// The review screen's failed state names which refusal it met: the proxy's
// 429 means three things (rate limit, today's ceiling, the grant spent) and
// a buyer must never read one as another. The spent grant offers the free
// door instead of a retry that would spend nothing and change nothing.

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

class _Refusing implements Extractor {
  _Refusing(this.error);
  final ExtractionException error;
  @override
  String get mode => 'image';
  @override
  String get modelName => 'test';
  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async =>
      throw error;
}

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recibook_failed_test');
  });

  tearDown(() => tmp.delete(recursive: true));

  Widget harness(ExtractionException error) => MultiProvider(
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
          // Keyed per refusal: the same widget type in the same slot would
          // keep its State (and its first error) across pumps.
          home: ImportReviewScreen(
            key: ValueKey(error.reason),
            images: const [],
            extractor: _Refusing(error),
            pickMore: () async => const [],
          ),
        ),
      );

  testWidgets('three 429s, three answers; 503 is our ceiling', (tester) async {
    await tester.pumpWidget(harness(
        ExtractionException('{}', httpStatus: 429, reason: 'rate_limited')));
    await tester.pumpAndSettle();
    expect(find.text('Give it a minute'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);

    await tester.pumpWidget(harness(
        ExtractionException('{}', httpStatus: 429, reason: 'daily_limit')));
    await tester.pumpAndSettle();
    expect(find.text("That's today's limit"), findsOneWidget);
    expect(find.textContaining('opens again tomorrow'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);

    await tester.pumpWidget(
        harness(ExtractionException('{}', httpStatus: 503, reason: 'busy')));
    await tester.pumpAndSettle();
    expect(find.text("We're busy right now"), findsOneWidget);
  });

  testWidgets('spent grant offers the free door, not a retry', (tester) async {
    await tester.pumpWidget(harness(
        ExtractionException('{}', httpStatus: 429, reason: 'cap_exceeded')));
    await tester.pumpAndSettle();
    expect(find.text("You've used your included rescues"), findsOneWidget);
    expect(find.textContaining('type it in instead, always free'),
        findsOneWidget);
    expect(find.byKey(const Key('review-type-it')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Try again'), findsNothing);
  });
}
