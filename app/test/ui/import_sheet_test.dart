// Import sheet allowance line (conductor/docs/ai-cap-mechanics.md §2): one quiet
// sentence of truth under the AI doors, the ~80% heads-up, and the spent
// grant turning the doors into the cap screen — whose free door pops the
// sheet with the manual choice, never a failed extraction.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/quota.dart';
import 'package:myrecibook/ui/byok_model.dart';
import 'package:myrecibook/ui/import_sheet.dart';
import 'package:myrecibook/ui/quota_model.dart';
import 'package:myrecibook/ui/theme.dart';
import 'package:provider/provider.dart';

void main() {
  final line = find.byKey(const Key('import-allowance-line'));
  const spent = 'included rescues used up — see your options';

  /// Opens the sheet over a host page. [quota] null with [providers] false
  /// pumps no providers at all — the sheet must cope, like the card does.
  Future<Future<ImportChoice?>> open(
    WidgetTester tester, {
    QuotaSnapshot? quota,
    bool ownKey = false,
    bool providers = true,
  }) async {
    // A sheet left open by the previous call would swallow the tap.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    final quotaModel = QuotaModel();
    if (quota != null) await quotaModel.record(quota);
    final byok = ByokModel();
    if (ownKey) await byok.setKey('AIza-test');
    late Future<ImportChoice?> result;
    final app = MaterialApp(
      theme: rbLightTheme(),
      home: Builder(
        builder: (ctx) => Scaffold(
          body: TextButton(
            onPressed: () {
              result = showImportSheet(
                ctx,
                picker: () async => [],
                camera: () async => [],
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.pumpWidget(providers
        ? MultiProvider(
            providers: [
              ChangeNotifierProvider<QuotaModel>.value(value: quotaModel),
              ChangeNotifierProvider<ByokModel>.value(value: byok),
            ],
            child: app,
          )
        : app);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('no line before the proxy has ever answered', (tester) async {
    await open(tester, providers: false);
    expect(line, findsNothing);
    await open(tester);
    expect(line, findsNothing);
    expect(find.text('one recipe or a whole pile — you decide next'),
        findsOneWidget);
  });

  testWidgets('the plain count, then the heads-up at 80%', (tester) async {
    await open(tester, quota: const QuotaSnapshot(used: 487, cap: 1200));
    expect(find.text('713 of 1,200 rescues left — each import uses one.'),
        findsOneWidget);

    await open(tester, quota: const QuotaSnapshot(used: 960, cap: 1200));
    expect(
        find.text('Heads-up: 960 of 1,200 used — 240 left, plenty for now.'),
        findsOneWidget);
  });

  testWidgets('free fortnight and own key say so instead of a count',
      (tester) async {
    await open(
      tester,
      quota: QuotaSnapshot(
        used: 0,
        cap: 1200,
        graceUntil: DateTime.now().toUtc().add(const Duration(days: 7)),
      ),
    );
    expect(find.text("Free for now — your first two weeks don't count."),
        findsOneWidget);

    // Own key: no cap, even with the grant spent — the doors stay doors.
    await open(tester,
        quota: const QuotaSnapshot(used: 1200, cap: 1200), ownKey: true);
    expect(find.text('Running on your own Gemini key — no cap.'),
        findsOneWidget);
    expect(find.text(spent), findsNothing);
  });

  testWidgets('spent grant: doors lead to the cap screen, free door pops manual',
      (tester) async {
    final result =
        await open(tester, quota: const QuotaSnapshot(used: 1200, cap: 1200));
    expect(
        find.text('Your 1,200 included rescues are used up — typing it in is '
            'always free.'),
        findsOneWidget);
    // All three AI doors (screenshots, link, camera) carry the spent caption.
    expect(find.text(spent), findsNWidgets(3));

    await tester.tap(find.byKey(const Key('import-screenshots-tile')));
    await tester.pumpAndSettle();
    expect(find.text("You've used your included rescues"), findsOneWidget);
    // The free path leads; the top-up waits for billing, honestly.
    expect(find.text('Type it in — always free'), findsOneWidget);
    expect(find.textContaining('arrive with billing'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cap-type-it')));
    await tester.pumpAndSettle();
    expect(await result, isA<ImportManual>());
  });

  testWidgets('paste a link: the door unfolds into a box, plain words are '
      'refused, a link pops ImportLink', (tester) async {
    // A caption with a link sits on the clipboard: the box opens pre-filled
    // with just the link.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return {'text': 'so good https://clip.example.com/pie try it'};
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    final result = await open(tester);
    expect(find.text('Paste a link'), findsOneWidget);
    expect(find.text('TikTok, IG, blog…'), findsOneWidget);

    await tester.tap(find.byKey(const Key('import-link-tile')));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('import-link-field'));
    expect(field, findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text,
        'https://clip.example.com/pie');
    // The doors are gone; the box and its button stand in their place.
    expect(find.text('Choose screenshots'), findsNothing);
    expect(find.text('Rescue from link'), findsOneWidget);

    await tester.enterText(field, 'grandma said add more butter');
    await tester.tap(find.byKey(const Key('import-link-cta')));
    await tester.pumpAndSettle();
    expect(find.textContaining("doesn't look like a link"), findsOneWidget);

    // A link buried in a shared caption is still found.
    await tester.enterText(
        field, 'Look at this https://example.com/buns?x=1 so good');
    await tester.pumpAndSettle();
    expect(find.textContaining("doesn't look like a link"), findsNothing);
    await tester.tap(find.byKey(const Key('import-link-cta')));
    await tester.pumpAndSettle();
    final choice = await result;
    expect(choice, isA<ImportLink>());
    expect((choice! as ImportLink).url, 'https://example.com/buns?x=1');
  });

  test('linkIn pulls the first http(s) link out of text', () {
    expect(linkIn('https://a.com/x'), 'https://a.com/x');
    expect(linkIn('see http://a.com/x and https://b.com'), 'http://a.com/x');
    expect(linkIn('no link here'), isNull);
    expect(linkIn('ftp://a.com'), isNull);
  });
}
