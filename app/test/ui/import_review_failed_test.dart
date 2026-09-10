// The review screen's failed state names which refusal it met: the proxy's
// 429 means three things (rate limit, today's ceiling, the grant spent) and
// a buyer must never read one as another. The spent grant offers the free
// door instead of a retry that would spend nothing and change nothing.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myrecibook/data/crash_log.dart';
import 'package:myrecibook/data/crash_reporter.dart';
import 'package:myrecibook/data/link_extractor.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/data/tag_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/ui/crash_reporting_model.dart';
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

/// Catches what the review screen sends down the crash pipe.
class _Sink implements CrashSink {
  final List<String> sent = [];
  final List<String?> contexts = [];
  final List<bool> fatal = [];

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<void> send(
    String error,
    StackTrace? stack, {
    String? context,
    required bool fatal,
    required List<String> breadcrumbs,
  }) async {
    sent.add(error);
    contexts.add(context);
    this.fatal.add(fatal);
  }
}

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recibook_failed_test');
  });

  tearDown(() => tmp.delete(recursive: true));

  Widget harness(ExtractionException error,
          {Extractor? extractor, CrashReportingModel? crash}) =>
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) =>
                  LibraryModel(LocalFolderStore(Directory('${tmp.path}/r')))),
          ChangeNotifierProvider(
              create: (ctx) => TagsModel(
                    store: MemoryTagStore(),
                    library: ctx.read<LibraryModel>(),
                  )),
          if (crash != null)
            ChangeNotifierProvider<CrashReportingModel>.value(value: crash),
        ],
        child: MaterialApp(
          theme: rbLightTheme(),
          // Keyed per refusal: the same widget type in the same slot would
          // keep its State (and its first error) across pumps.
          home: ImportReviewScreen(
            key: ValueKey(error.reason),
            images: const [],
            extractor: extractor ?? _Refusing(error),
            pickMore: () async => const [],
          ),
        ),
      );

  testWidgets('a refused link goes down the crash pipe as a non-fatal with '
      'the host, never the URL', (tester) async {
    final sink = _Sink();
    final crash = CrashReportingModel(
      reporter: CrashReporter(log: CrashLog.inert(), sink: sink, enabled: true),
    );
    const url = 'https://www.allrecipes.com/chicken-alfredo-recipe-12112506';
    final wall = LinkExtractor(
      url: url,
      client: MockClient((_) async => http.Response('go away', 402)),
    );
    await tester.pumpWidget(harness(
      ExtractionException('unused'),
      extractor: wall,
      crash: crash,
    ));
    await tester.pumpAndSettle();
    expect(find.text("The site wouldn't let us in"), findsOneWidget);

    expect(sink.sent, hasLength(1));
    expect(sink.sent.single,
        'rescue failed (link · 402 · www.allrecipes.com): the page answered 402');
    expect(sink.sent.single, isNot(contains('chicken-alfredo')));
    expect(sink.contexts.single, 'rescue failed');
    expect(sink.fatal.single, isFalse);
  });

  testWidgets('no crash model in the tree: the failed state still shows',
      (tester) async {
    await tester.pumpWidget(harness(
        ExtractionException('the page answered 403', httpStatus: 403)));
    await tester.pumpAndSettle();
    expect(find.text("The site wouldn't let us in"), findsOneWidget);
  });

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
